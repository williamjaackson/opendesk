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
    else
      text_field_tag name, value, id: id, class: classes, required: required
    end
  end
end
