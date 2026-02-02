module ButtonsHelper
  def button_classes(variant = :primary)
    base = "px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer select-none"

    case variant
    when :primary
      "#{base} bg-[var(--theme-colour)] text-white hover:bg-[var(--theme-colour-hover)] shadow-sm"
    when :ghost
      "#{base} bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
    end
  end
end
