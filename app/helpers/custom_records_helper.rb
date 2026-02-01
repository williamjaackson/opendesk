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
      date_field_tag name, value, id: id, class: classes, required: required
    when "time"
      time_field_tag name, value, id: id, class: classes, required: required
    when "datetime"
      datetime_local_field_tag name, value, id: id, class: classes, required: required
    else
      text_field_tag name, value, id: id, class: classes, required: required
    end
  end

  def format_column_value(column, raw_value)
    case column.column_type
    when "boolean"
      return "—" if raw_value.nil?
      raw_value == "1" ? "Yes" : "No"
    when "time"
      return "—" if raw_value.blank?
      format_time_for_display(raw_value)
    when "datetime"
      return "—" if raw_value.blank?
      format_datetime_for_display(raw_value)
    else
      raw_value
    end
  end

  private

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
