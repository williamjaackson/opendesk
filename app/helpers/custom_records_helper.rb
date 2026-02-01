module CustomRecordsHelper
  def column_value_tag(column, value, required:, errors: false)
    name = "values[#{column.id}]"
    id = "values_#{column.id}"
    border = errors ? "border-red-300 focus:border-red-500 focus:ring-red-500" : "border-gray-300 focus:border-gray-500 focus:ring-gray-500"
    classes = "block w-full rounded-md border #{border} bg-white px-3 py-2 text-sm focus:outline-none focus:ring-1"

    case column.column_type
    when "number"
      text_field_tag name, value, id: id, class: classes, required: required, inputmode: "numeric", pattern: "[0-9]+"
    when "email"
      email_field_tag name, value, id: id, class: classes, required: required
    when "boolean"
      checked = value == "1"
      tag.div data: { controller: "checkbox" } do
        hidden_field_tag(name, checked ? "1" : "0", id: id, data: { checkbox_target: "input" }) +
        tag.div(tabindex: 0, role: "checkbox", "aria-checked": checked.to_s, "aria-label": column.name,
          data: { action: "click->checkbox#toggle keydown->checkbox#keydown" },
          class: "inline-flex items-center gap-2 cursor-pointer select-none group") {
          tag.span(data: { checkbox_target: "box" },
            class: "flex shrink-0 items-center justify-center h-5 w-5 rounded border transition-colors #{checked ? 'bg-gray-900 border-gray-900' : 'bg-white border-gray-300'} group-focus:ring-2 group-focus:ring-gray-500 group-focus:ring-offset-1") {
            tag.svg(viewBox: "0 0 12 10", fill: "none", class: "h-3 w-3 text-white #{checked ? '' : 'invisible'}", data: { checkmark: "" }) {
              tag.path(d: "M1 5.5L4 8.5L11 1.5", stroke: "currentColor", "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round")
            }
          } +
          tag.span(column.name, class: "text-sm font-medium text-gray-700")
        }
      end
    when "date"
      display_value = value.present? ? (Date.parse(value).strftime("%-d %b %Y") rescue value) : ""
      tag.div class: "relative", data: { controller: "datepicker" } do
        hidden_field_tag(name, value, id: id, data: { datepicker_target: "input" }) +
        tag.input(type: "text", readonly: true, value: display_value, placeholder: "Select a date",
          tabindex: 0,
          data: { datepicker_target: "display", action: "click->datepicker#toggle keydown->datepicker#keydown" },
          class: "#{classes} cursor-pointer pr-10") +
        tag.div(class: "pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3") {
          tag.svg(class: "h-4 w-4 text-gray-400", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") {
            tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
              d: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z")
          }
        } +
        tag.div(class: "hidden absolute z-10 mt-1 w-72 bg-white rounded-lg border border-gray-200 shadow-lg",
          data: { datepicker_target: "calendar" })
      end
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
      return raw_value if raw_value.blank?
      Date.parse(raw_value).strftime("%-d %b %Y")
    else
      raw_value
    end
  end
end
