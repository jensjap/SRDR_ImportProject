class BaseType
    attr_reader :section, :question_number, :question_text

    def initialize(section, question_number, question_text)
        @section = section
        @question_number = question_number
        @question_text = question_text
    end
end

class CheckboxType < BaseType
end

class MatrixRadioType < BaseType
end

class MatrixValueType < BaseType
end

class RadioType < BaseType
end

class TextType < BaseType
end
