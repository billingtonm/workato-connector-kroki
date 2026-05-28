# download html from https://kroki.io/#support
# look for table with diagram types - it is at: 
#   /html/body/section[@class="section"]/div[@class="container"]/div[@class="duo"]/div[@class="lead"]/div[@class="content"]/div[@class="table-container"]/table[@class="table table-support is-bordered is-striped is-narrow is-hoverable is-fullwidth"]

# this table is laid out as follows:
#   thead:
#     first column (th) = "Diagram type"
#     columns 2 ... N = "Output formats"
#   tbody:
#     each row (tr) corresponds to a diagram type, with:
#       first column (td) = diagram type name
#       columns 2 ... N = indicator of whether that output format is supported for that diagram type (e.g. "✓"). An empty cell indicates that the output format is not supported for that diagram type.

def get_diagram_types
  require 'nokogiri'
  require 'open-uri'

  url = "https://kroki.io/#support"
  html = URI.open(url)
  doc = Nokogiri::HTML(html)

  table = doc.at_xpath('/html/body/section[@class="section"]/div[@class="container"]/div[@class="duo"]/div[@class="lead"]/div[@class="content"]/div[@class="table-container"]/table[@class="table table-support is-bordered is-striped is-narrow is-hoverable is-fullwidth"]')

  # Extract the header row to get the output formats
  header_row = table.at_xpath('thead/tr')
  output_formats = header_row.xpath('th[position() > 1]').map(&:text).map(&:strip)

  # Extract the body rows to get the diagram types and their supported output formats
  diagram_types = []
  table.xpath('tbody/tr').each do |row|
    diagram_type_name = row.at_xpath('td[1]').text.strip
    types_td = row.xpath('td[position() > 1]')
    selected = types_td.each_with_index.select { |td, index| td.text.strip.include?("✔️") }
    supported = selected.map { |_, index| output_formats[index] }
    
    diagram_types << { 
      diagram: diagram_type_name.gsub(" with ", "").gsub("-", "").downcase,
      diagram_label: diagram_type_name, 
      supported: supported }
  end
  
  diagram_types.sort_by! { |dt| dt[:diagram] }
end

puts "[\n#{get_diagram_types.map { |dt| "\t#{dt.to_s}"}.join(",\n")}\n]\n"

