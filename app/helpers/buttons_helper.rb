module ButtonsHelper
  def button_classes(variant = :primary)
    base = "px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer"

    case variant
    when :primary
      "#{base} bg-gray-900 text-white hover:bg-gray-800 shadow-sm"
    when :ghost
      "#{base} bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
    end
  end
end
