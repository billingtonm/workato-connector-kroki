{
  # Connector: (c) Innovation Quotient Pty Ltd Australia, 2026
  # Author: Matthew Billington
  title: 'Kroki - Diagram from Code',

  # ---------------------------------------------------------------------------
  connection: {

    base_uri: lambda do |connection|
      'https://kroki.io'
    end
  }, # end of connection

  # ---------------------------------------------------------------------------
  test: lambda do |connection|
    true
  end,

  # ---------------------------------------------------------------------------
  object_definitions: {}, # end of object_definitions

  # ---------------------------------------------------------------------------
  # Reusable methods can be called from object_definitions, picklists or actions
  # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/methods.html
  methods: {
    # Utility methods

    # returns a field that is an array of another object defintion
    make_array: lambda do |name, label, definition|
      {
        name: name,
        label: label,
        type: :array,
        of: :object,
        properties: definition
      }
    end, # end of method: make_array

    # makes a field in an input form a toggle field
    make_toggle_field: lambda do |field|
      field.merge({
                    toggle_hint: field[:control_type] == :tree ? 'Select folder' : 'Select from list',
                    toggle_field: {
                      toggle_hint: 'Use value',
                      name: field[:name],
                      label: field[:label] || field[:name].labelize,
                      type: field.fetch(:type, 'string'),
                      control_type: field.fetch(:type, :text),
                      optional: field.fetch(:optional, false),
                      hint: (field[:hint] || '')\
                 + (field[:hint].present? ? '. ' : '')\
                 + (field[:delimiter].present? ? "List of #{field[:label].pluralize} seperated by '#{field[:delimiter]}'." : '')
                    }
                  })
    end,

    # This method will retrieve the diagram types supported by Kroki from the
    # website and the output formats supported for each diagram type.
    # It is used to generate the the data for the 'diagram_types' method,
    # which is used to populate the picklist for diagram types in the action input fields.
    # It called be called dynamically, but for performance reasons it is only
    # used to generate the static data for the 'diagram_types' method, which is called by the action input fields.
    get_diagram_types: lambda do
      require 'nokogiri'
      require 'open-uri'

      url = 'https://kroki.io/#support'
      html = URI.open(url)
      doc = Nokogiri::HTML(html)

      table = doc.at_xpath('/html/body/section[@class="section"]/' \
        'div[@class="container"]/div[@class="duo"]/div[@class="lead"]/' \
        'div[@class="content"]/div[@class="table-container"]/' \
        'table[@class="table table-support is-bordered is-striped is-narrow is-hoverable is-fullwidth"]')

      # Extract the header row to get the output formats
      header_row = table.at_xpath('thead/tr')
      output_formats = header_row.xpath('th[position() > 1]').map(&:text).map(&:strip)

      # Extract the body rows to get the diagram types and their supported output formats
      diagram_types = []
      table.xpath('tbody/tr').each do |row|
        diagram_type_name = row.at_xpath('td[1]').text.strip
        types_td = row.xpath('td[position() > 1]')
        selected = types_td.each_with_index.select { |td, index| td.text.strip.include?('✔️') }
        supported = selected.map { |_, index| output_formats[index] }

        diagram_types << { diagram: diagram_type_name, supported: supported }
      end

      diagram_types.sort_by! { |dt| dt[:diagram] }
    end, # end of method: get_diagram_types

    # Static data generated from the get_diagram_types method, which is used
    # to populate the picklist for diagram types in the action input fields.
    diagram_types: lambda do
      [
        { diagram: 'actdiag', diagram_label: 'ActDiag', supported: %w[png svg pdf] },
        { diagram: 'blockdiag', diagram_label: 'BlockDiag', supported: %w[png svg pdf] },
        { diagram: 'bpmn', diagram_label: 'BPMN', supported: ['svg'] },
        { diagram: 'bytefield', diagram_label: 'Bytefield', supported: ['svg'] },
        { diagram: 'c4plantuml', diagram_label: 'C4 with PlantUML', supported: %w[png svg pdf txt base64] },
        { diagram: 'd2', diagram_label: 'D2', supported: ['svg'] },
        { diagram: 'dbml', diagram_label: 'DBML', supported: ['svg'] },
        { diagram: 'ditaa', diagram_label: 'Ditaa', supported: %w[png svg] },
        { diagram: 'erd', diagram_label: 'Erd', supported: %w[png svg jpeg pdf] },
        { diagram: 'excalidraw', diagram_label: 'Excalidraw', supported: ['svg'] },
        { diagram: 'graphviz', diagram_label: 'GraphViz', supported: %w[png svg jpeg pdf] },
        { diagram: 'mermaid', diagram_label: 'Mermaid', supported: %w[png svg] },
        { diagram: 'nomnoml', diagram_label: 'Nomnoml', supported: ['svg'] },
        { diagram: 'nwdiag', diagram_label: 'NwDiag', supported: %w[png svg pdf] },
        { diagram: 'packetdiag', diagram_label: 'PacketDiag', supported: %w[png svg pdf] },
        { diagram: 'pikchr', diagram_label: 'Pikchr', supported: ['svg'] },
        { diagram: 'plantuml', diagram_label: 'PlantUML', supported: %w[png svg pdf txt base64] },
        { diagram: 'rackdiag', diagram_label: 'RackDiag', supported: %w[png svg pdf] },
        { diagram: 'seqdiag', diagram_label: 'SeqDiag', supported: %w[png svg pdf] },
        { diagram: 'structurizr', diagram_label: 'Structurizr', supported: %w[png svg pdf txt base64] },
        { diagram: 'svgbob', diagram_label: 'Svgbob', supported: ['svg'] },
        { diagram: 'symbolator', diagram_label: 'Symbolator', supported: ['svg'] },
        { diagram: 'tikz', diagram_label: 'TikZ', supported: %w[png svg jpeg pdf] },
        { diagram: 'umlet', diagram_label: 'UMlet', supported: %w[png svg jpeg] },
        { diagram: 'vega', diagram_label: 'Vega', supported: %w[png svg pdf] },
        { diagram: 'vegalite', diagram_label: 'Vega-Lite', supported: %w[png svg pdf] },
        { diagram: 'wavedrom', diagram_label: 'WaveDrom', supported: ['svg'] },
        { diagram: 'wireviz', diagram_label: 'WireViz', supported: %w[png svg] }
      ]
    end, # end method: diagram_types

    deflate_base64encode: lambda do |string|
      require 'zlib'
      require 'base64'

      deflated = Zlib::Deflate.deflate(string)
      deflated.encode_urlsafe_base64
    end,

    get_diagram: lambda do |input|
      base_uri = 'https://kroki.io'

      diagram = input.delete('diagram')
      format = input.delete('format')
      definition = input.delete('diagram_definition')

      url = "#{base_uri}/#{diagram}/#{format}/#{call(:deflate_base64encode, definition)}"

      output = get(url).params(input).response_format_raw

      if diagram == 'plantuml' && format == 'svg'
        # Remove the plantuml header from the file. Confluence doesn't like it!
        output = output.sub('<?plantuml 1.2026.1?>', '')
      end

      { url: url, output: output }
    end

  }, # end of methods

  # ---------------------------------------------------------------------------
  actions: {
    generate_diagram: {
      title: 'Generate diagram from text',
      subtitle: '',
      help: lambda do |input, picklist_label|
        { body: '',
          learn_more_url: 'https://docs.workato.com/en/workato-api/folders.html#list-projects',
          learn_more_text: 'Learn more' }
      end,
      description: lambda do |input, picklist_label|
        "Generate a <span class='provider'>#{picklist_label['diagram'].to_s + ' '}" \
        "diagram</span> in <span class='provider'>Kroki</span>"
      end,

      config_fields:
        [
          {
            name: 'diagram',
            label: 'Diagram Type',
            type: :string,
            control_type: :select,
            pick_list: :diagram_types,
            hint: 'Select the type of diagram to generate',
            optional: false
          },
          {
            name: 'format',
            label: 'Output Format',
            type: :string,
            control_type: :select,
            pick_list: :formats_for_diagram_type,
            hint: 'Select the output format type',
            optional: false,
            pick_list_params: { diagram_type: 'diagram' }
          }
        ],

      input_fields: lambda do |object_definitions, connection, config_fields|
        [
          { name: 'diagram_definition', label: 'Diagram definition', type: :string, control_type: :text,
            optional: false }
        ]
      end,

      output_fields: lambda do |object_definitions, connection, config_fields|
        [
          { name: 'url',    label: 'URL to output diagram', type: :string },
          { name: 'output', label: 'Output diagram', type: :string }
        ]
      end,

      execute: lambda do |connection, input|
        call(:get_diagram, input)
      end

    } # end of action_1

  }, # end of actions

  # ---------------------------------------------------------------------------
  triggers: {}, # end of triggers

  # ---------------------------------------------------------------------------
  # Picklists can be referenced by inputs fields or object_definitions
  # possible arguements - connection
  # see more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/picklists.html
  pick_lists: {

    diagram_types: lambda do |_connection|
      call(:diagram_types)
        .map { |dt| [dt[:diagram_label], dt[:diagram]] }
    end, # end of picklist: diagram_types

    formats_for_diagram_type: lambda do |_connection, diagram_type:|
      call(:diagram_types).where(diagram: diagram_type).first[:supported]
                          .map { |format| [format, format] }
    end # end of picklist: formats_for_diagram_type

  } # end of pick_lists

}
