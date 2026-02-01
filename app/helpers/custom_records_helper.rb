module CustomRecordsHelper
  def column_value_tag(column, value, required:)
    name = "values[#{column.id}]"
    id = "values_#{column.id}"
    classes = "block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm focus:border-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-500"

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
    else
      text_field_tag name, value, id: id, class: classes, required: required
    end
  end

  def format_column_value(column, raw_value)
    case column.column_type
    when "boolean"
      return "—" if raw_value.nil?
      raw_value == "1" ? "Yes" : "No"
    else
      raw_value
    end
  end
end
