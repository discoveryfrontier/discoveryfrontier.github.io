# Checks the site's _data files so a typo can't silently drop a paper from the page.
# Usage: bundle exec ruby scripts/validate_data.rb
require "yaml"
require "uri"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "_data")
errors = []

def load(name)
  YAML.safe_load(File.read(File.join(DATA, name)))
end

def https_url?(value)
  uri = URI.parse(value.to_s)
  uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?
rescue URI::InvalidURIError
  false
end

stages = load("stages.yml")
stage_keys = stages.map { |s| s["key"] }
errors << "stages.yml: duplicate stage keys" if stage_keys.uniq.size != stage_keys.size
stages.each do |s|
  %w[key label blurb color].each { |k| errors << "stages.yml: stage #{s.inspect} is missing #{k}" if s[k].to_s.strip.empty? }
  errors << "stages.yml: #{s['key']} color must be #rrggbb" unless s["color"].to_s.match?(/\A#\h{6}\z/)
end

papers = load("papers.yml")
required = %w[id short title tldr venue venue_short year stage paper]
allowed = required + %w[code note]
papers.each_with_index do |p, i|
  where = "papers.yml entry #{i + 1} (#{p['short'] || p['title'] || '?'})"
  required.each { |k| errors << "#{where}: missing #{k}" if p[k].nil? || p[k].to_s.strip.empty? }
  (p.keys - allowed).each { |k| errors << "#{where}: unknown field #{k}" }
  errors << "#{where}: year must be a number" unless p["year"].is_a?(Integer)
  errors << "#{where}: id must be lowercase kebab-case" unless p["id"].to_s.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
  errors << "#{where}: missing image assets/img/papers/#{p['id']}.jpg" unless File.exist?(File.join(ROOT, "assets/img/papers/#{p['id']}.jpg"))
  errors << "#{where}: stage '#{p['stage']}' is not in stages.yml" unless stage_keys.include?(p["stage"])
  errors << "#{where}: paper must be an https URL" unless https_url?(p["paper"])
  errors << "#{where}: code must be an https URL" if p["code"] && !https_url?(p["code"])
end
%w[id title paper].each do |k|
  dupes = papers.map { |p| p[k] }.tally.select { |_, n| n > 1 }.keys
  dupes.each { |d| errors << "papers.yml: duplicate #{k} #{d}" }
end

team = load("team.yml")["contacts"]
team.each do |m|
  %w[name affiliation email].each { |k| errors << "team.yml: #{m['name'] || '?'} is missing #{k}" if m[k].to_s.strip.empty? }
  errors << "team.yml: #{m['name']} email looks wrong" unless m["email"].to_s.match?(/\A[^@\s]+@[^@\s]+\.[a-z]{2,}\z/i)
end

# Unreleased work gets a name and a status, nothing more.
(load("upcoming.yml") || []).each do |u|
  extra = u.keys - %w[name status]
  errors << "upcoming.yml: #{u['name']} has fields #{extra.join(', ')}; only name and status are allowed" unless extra.empty?
end

if errors.empty?
  puts "Data OK: #{papers.size} papers, #{stages.size} stages, #{team.size} contacts."
else
  warn errors.map { |e| "  - #{e}" }.join("\n")
  abort "#{errors.size} data error(s)."
end
