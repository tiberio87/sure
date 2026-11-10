#!/usr/bin/env ruby
# frozen_string_literal: true
# Structural check: per-file parity with the English locale, including
# interpolation placeholders. This does not replace native-speaker UI review.
require "yaml"
require "set"

root = File.expand_path("../config/locales", __dir__)
english = Dir.glob(File.join(root, "**", "en.yml")).sort
abort "No English locale files found" if english.empty?

def flattened(obj, prefix = "", result = {})
  case obj
  when Hash
    obj.each do |key, value|
      path = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      flattened(value, path, result)
    end
  else
    result[prefix] = obj
  end
  result
end

errors = []
english.each do |en_file|
  it_file = en_file.sub(/\/en\.yml\z/, "/it.yml")
  unless File.file?(it_file)
    errors << "Missing Italian file: #{it_file.delete_prefix(root + "/")}"
    next
  end
  begin
    en = YAML.safe_load_file(en_file, aliases: true)
    it = YAML.safe_load_file(it_file, aliases: true)
    abort "Invalid locale root: #{en_file}" unless en.is_a?(Hash) && en.key?("en")
    abort "Invalid locale root: #{it_file}" unless it.is_a?(Hash) && it.key?("it")
    en_keys = flattened(en.fetch("en"))
    it_keys = flattened(it.fetch("it"))
    (en_keys.keys - it_keys.keys).each { |key| errors << "Missing: #{it_file.delete_prefix(root + "/")} #{key}" }
    (en_keys.keys & it_keys.keys).each do |key|
      next unless en_keys[key].is_a?(String) && it_keys[key].is_a?(String)
      expected = en_keys[key].scan(/%\{[^}]+\}/).sort
      actual = it_keys[key].scan(/%\{[^}]+\}/).sort
      errors << "Interpolation mismatch: #{it_file.delete_prefix(root + "/")} #{key}: #{expected.inspect} != #{actual.inspect}" unless expected == actual
    end
  rescue Psych::Exception => error
    errors << "Invalid YAML: #{it_file}: #{error.message}"
  end
end

if errors.any?
  warn errors.first(100).join("\n")
  warn "#{errors.length} errors (showing first 100)"
  exit 1
end
puts "OK: #{english.length} English/Italian locale files; no missing keys or interpolation mismatches"
