module CustomRecordsHelper
  def column_value_tag(column, value, required:, errors: false)
    name = "values[#{column.id}]"
    id = "values_#{column.id}"
    border = errors ? "border-red-300 focus:border-red-500 focus:ring-red-500" : "border-gray-300 focus:border-gray-500 focus:ring-gray-500"

    type_input_tag(column.column_type, name, id, value, border: border, required: required,
      select_options: column.column_type == "select" ? column.effective_options : [], label: column.name)
  end

  def type_input_tag(type, name, id, value, border:, required: false, select_options: [], label: nil)
    classes = "block w-full rounded-md border #{border} bg-white px-3 py-2 text-sm focus:outline-none focus:ring-1"

    case type
    when "number"
      text_field_tag name, value, id: id, class: classes, required: required, inputmode: "numeric", pattern: "[0-9]+"
    when "decimal"
      text_field_tag name, value, id: id, class: classes, required: required, inputmode: "decimal", pattern: "[0-9]+(\.[0-9]+)?"
    when "email"
      email_field_tag name, value, id: id, class: classes, required: required
    when "boolean"
      checked = value == "1"
      tag.div data: { controller: "checkbox" } do
        hidden_field_tag(name, checked ? "1" : "0", id: id, data: { checkbox_target: "input" }) +
        tag.div(tabindex: 0, role: "checkbox", "aria-checked": checked.to_s, "aria-label": label,
          data: { action: "click->checkbox#toggle keydown->checkbox#keydown" },
          class: "inline-flex items-center gap-2 cursor-pointer select-none group") {
          tag.span(data: { checkbox_target: "box" },
            class: "flex shrink-0 items-center justify-center h-5 w-5 rounded border transition-colors #{checked ? 'bg-gray-900 border-gray-900' : 'bg-white border-gray-300'} group-focus:ring-2 group-focus:ring-gray-500 group-focus:ring-offset-1") {
            tag.svg(viewBox: "0 0 12 10", fill: "none", class: "h-3 w-3 text-white #{checked ? '' : 'invisible'}", data: { checkmark: "" }) {
              tag.path(d: "M1 5.5L4 8.5L11 1.5", stroke: "currentColor", "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round")
            }
          } +
          tag.span(label, class: "text-sm font-medium text-gray-700")
        }
      end
    when "date"
      date_field_tag name, value, id: id, class: classes, required: required
    when "time"
      time_field_tag name, value, id: id, class: classes, required: required
    when "datetime"
      datetime_local_field_tag name, value, id: id, class: classes, required: required
    when "select"
      select_dropdown_tag(name, id, value, select_options, border)
    when "currency"
      currency_input_tag(name, id, value, border)
    when "colour"
      color_field_tag name, value.presence || "#000000", id: id, class: "h-10 w-20 rounded-md border #{border} bg-white p-1 cursor-pointer"
    else
      text_field_tag name, value, id: id, class: classes, required: required
    end
  end

  def format_column_value(column, raw_value)
    case column.column_type
    when "boolean"
      return "—" if raw_value.nil?
      raw_value == "1" ? "Yes" : "No"
    when "date"
      return "—" if raw_value.blank?
      raw_value
    when "time"
      return "—" if raw_value.blank?
      format_time_for_display(raw_value)
    when "datetime"
      return "—" if raw_value.blank?
      format_datetime_for_display(raw_value)
    when "select"
      return "—" if raw_value.blank?
      raw_value
    when "currency"
      return "—" if raw_value.blank?
      format_currency_for_display(raw_value)
    when "colour"
      return "—" if raw_value.blank?
      format_colour_for_display(raw_value)
    else
      raw_value
    end
  end

  private

  def select_dropdown_tag(name, id, value, options, border)
    selected_label = options.include?(value) ? value : ""

    tag.div(data: { controller: "dropdown", action: "keydown->dropdown#keydown" }, class: "relative") do
      hidden_field_tag(name, value, id: id, data: { dropdown_target: "input" }) +
      tag.div(class: "relative") do
        tag.input(
          type: "text", readonly: true, placeholder: "Select...", value: selected_label,
          data: { action: "click->dropdown#toggle", dropdown_target: "button" },
          class: "block w-full rounded-md border #{border} bg-white px-3 py-2 pr-8 text-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-1 cursor-pointer"
        ) +
        lucide_icon("chevron-down", class: "absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none")
      end +
      tag.div(data: { dropdown_target: "menu" }, class: "hidden absolute z-10 mt-1 w-full rounded-md border border-gray-200 bg-white shadow-lg max-h-60 overflow-y-auto") do
        tag.div(class: "sticky top-0 bg-white border-b border-gray-200 p-1.5") do
          tag.input(
            type: "text", placeholder: "Search...",
            data: { dropdown_target: "search", action: "input->dropdown#filter" },
            class: "w-full rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm focus:border-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-500"
          )
        end +
        tag.div(class: "py-1") do
          safe_join(options.map do |opt|
            tag.button(
              type: "button", tabindex: "-1",
              data: { action: "dropdown#select", value: opt, label: opt },
              class: "flex items-center justify-between w-full px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 cursor-pointer"
            ) do
              tag.span(opt) +
              tag.span(data: { check: "" }, class: opt == value ? "" : "invisible") do
                lucide_icon("check", class: "h-4 w-4 text-gray-900")
              end
            end
          end)
        end
      end
    end
  end

  def currency_input_tag(name, id, value, border)
    wrapper_border = border.gsub("focus:", "focus-within:")

    tag.div(data: { controller: "currency-input" }) do
      hidden_field_tag(name, value, id: "#{id}_hidden", data: { currency_input_target: "input" }) +
      tag.div(class: "flex items-center rounded-md border #{wrapper_border} bg-white text-sm focus-within:ring-1") do
        tag.span("$", class: "pl-3 pr-1 text-gray-500 select-none") +
        tag.input(
          type: "text", id: id,
          data: { currency_input_target: "dollars", action: "input->currency-input#update keydown->currency-input#dollarsKeydown" },
          class: "border-0 bg-transparent py-2 px-0 text-sm focus:outline-none focus:ring-0",
          placeholder: "0", size: 1,
          aria: { label: "Dollars" }
        ) +
        tag.span(".", class: "text-gray-500 select-none") +
        tag.input(
          type: "text", inputmode: "numeric", maxlength: 2,
          data: { currency_input_target: "cents", action: "input->currency-input#update blur->currency-input#padCents keydown->currency-input#centsKeydown" },
          class: "w-16 border-0 bg-transparent py-2 px-1 text-sm focus:outline-none focus:ring-0",
          placeholder: "00",
          aria: { label: "Cents" }
        )
      end
    end
  end

  def format_colour_for_display(value)
    swatch = tag.span("", class: "inline-block h-4 w-4 rounded border border-gray-300 align-text-bottom", style: "background-color: #{ERB::Util.html_escape(value)}")
    swatch + tag.span(value, class: "ml-1.5")
  end

  def format_currency_for_display(value)
    return value unless value.match?(/\A\d+\.\d{2}\z/)
    dollars, cents = value.split(".")
    formatted_dollars = dollars.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    "$#{formatted_dollars}.#{cents}"
  end

  def format_time_for_display(value)
    return "" if value.blank?
    hours, minutes = value.split(":").map(&:to_i)
    period = hours >= 12 ? "PM" : "AM"
    hour12 = hours % 12
    hour12 = 12 if hour12 == 0
    "#{hour12}:#{format('%02d', minutes)} #{period}"
  rescue
    value
  end

  def format_datetime_for_display(value)
    return "" if value.blank?
    date_part, time_part = value.split("T")
    date = Date.parse(date_part)
    formatted_date = date.strftime("%-d %b %Y")
    formatted_time = format_time_for_display(time_part)
    "#{formatted_date}, #{formatted_time}"
  rescue
    value
  end
end
