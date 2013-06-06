def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end

def next_question?
    return false  # TODO: stub
end

class ExtractionFormQuestion
    attr_reader :section, :question_number, :question_text

    def initialize(section, question_number, question_text)
        @section = section
        @question_number = question_number
        @question_text = question_text
    end

    def to_s
        "Section: #{@section}--#{@question_number}. #{@question_text}"
    end
end

class QuestionType < ExtractionFormQuestion
    attr_reader :question_type, :question_code, :answ_text, :answ_value,
        :answ_code, :matrix_row, :matrix_row_code, :matrix_col,
        :matrix_col_val, :matrix_col_code, :instruction

    def initialize(section, question_number, question_text,
                    question_type, question_code, answ_text,
                    answ_value, answ_code, matrix_row, matrix_row_code,
                    matrix_col, matrix_col_val, matrix_col_code,
                    instruction)
        super(section, question_number, question_text)
        @question_type = question_type
        @question_code = question_code
        @answ_text = answ_text
        @answ_value = answ_value
        @answ_code = answ_code
        @matrix_row = matrix_row
        @matrix_row_code = matrix_row_code
        @matrix_col = matrix_col
        @matrix_col_val = matrix_col_val
        @matrix_col_code = matrix_col_code
        @instruction = instruction
    end

    def to_s
        super + "--" + @answ_text.to_s
    end
end
