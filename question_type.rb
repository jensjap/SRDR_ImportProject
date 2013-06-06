class BaseType
    attr_reader :section, :question_number, :question_text, :instruction

    @@lookup = { 'A' => 0,      # Section
                 'B' => 1,      # Q_number
                 'C' => 2,      # Q_text
                 'D' => 3,      # Q_type
                 'E' => 4,      # Q_code
                 'F' => 5,      # A_text
                 'G' => 6,      # A_value
                 'H' => 7,      # A_code
                 'I' => 8,      # M_row
                 'J' => 9,      # M_row_code
                 'K' => 10,     # M_col
                 'L' => 11,     # M_col_value
                 'M' => 12,     # M_col_code
                 'N' => 13,     # Instruction
    }

    def initialize(row, extraction_form_id)
        @section = row[@@lookup['A']].downcase
        @question_number = row[@@lookup['B']]
        @question_text = row[@@lookup['C']]
        @question_type = row[@@lookup['D']]
        @instruction = row[@@lookup['N']]
        @extraction_form_id = extraction_form_id
    end

    def to_s
        self.id.to_s + "--" + @section + "--" + @question_type
    end

    def id
        @section + @question_number.to_s
    end
end

class CheckboxType < BaseType
    attr_reader :answer_text, :answer_code

    def initialize(row, extraction_form_id)
        super(row, extraction_form_id)
        @answer_text = row[@@lookup['F']]
        @answer_code = row[@@lookup['H']]
    end

    def build
        case @section
        when 'baseline characteristic'
            unless BaselineCharacteristic.scoped_by_extraction_form_id(@extraction_form_id).exists?(question: @question_text)
                bc = BaselineCharacteristic.new
                bc.question = @question_text
                bc.field_type = @question_type
                bc.extraction_form_id = @extraction_form_id
                bc.field_notes = nil
                bc.question_number = BaselineCharacteristic.find_all_by_extraction_form_id(@extraction_form_id).length + 1
                bc.study_id = nil
                bc.instruction = @instruction
                bc.is_matrix = 0
                bc.include_other_as_option = nil
                bc.save
            else
                bc = BaselineCharacteristic.scoped_by_extraction_form_id(@extraction_form_id).find_by_question(@question_text)
            end
            bcf = BaselineCharacteristicField.new
            bcf.baseline_characteristic_id = bc.id
            bcf.option_text = @answer_text
            if @answer_text.downcase.include?('other')
                bcf.subquestion = 'Please specify: '
                bcf.has_subquestion = 1
            else
                bcf.subquestion = nil
                bcf.has_subquestion = 0
            end
            bcf.column_number = 0
            bcf.row_number = BaselineCharacteristicField.find_all_by_baseline_characteristic_id(bc.id).length + 1
            bcf.save
        when 'design'
            unless DesignDetail.scoped_by_extraction_form_id(@extraction_form_id).exists?(question: @question_text)
                dd = DesignDetail.new
                dd.question = @question_text
                dd.extraction_form_id = @extraction_form_id
                dd.field_type = @question_type
                dd.field_note = nil
                dd.question_number = DesignDetail.find_all_by_extraction_form_id(@extraction_form_id).length + 1
                dd.study_id = nil
                dd.instruction = @instruction
                dd.is_matrix = 0
                dd.include_other_as_option = nil
                dd.save
            else
                dd = DesignDetail.scoped_by_extraction_form_id(@extraction_form_id).find_by_question(@question_text)
            end
            ddf = DesignDetailField.new
            ddf.design_detail_id = dd.id
            ddf.option_text = @answer_text
            if @answer_text.downcase.include?('other')
                ddf.subquestion = 'Please specify: '
                ddf.has_subquestion = 1
            else
                ddf.subquestion = nil
                ddf.has_subquestion = 0
            end
            ddf.column_number = 0
            ddf.row_number = DesignDetailField.find_all_by_design_detail_id(dd.id).length + 1
            ddf.save
        when 'outcome detail'
            unless OutcomeDetail.scoped_by_extraction_form_id(@extraction_form_id).exists?(question: @question_text)
                od = OutcomeDetail.new
                od.question = @question_text
                od.extraction_form_id = @extraction_form_id
                od.field_type = @question_type
                od.field_note = nil
                od.question_number = OutcomeDetail.find_all_by_extraction_form_id(@extraction_form_id).length + 1
                od.study_id = nil
                od.instruction = @instruction
                od.is_matrix = 0
                od.include_other_as_option = nil
                od.save
            else
                od = OutcomeDetail.scoped_by_extraction_form_id(@extraction_form_id).find_by_question(@question_text)
            end
            odf = OutcomeDetailField.new
            odf.outcome_detail_id = od.id
            odf.option_text = @answer_text
            if @answer_text.downcase.include?('other')
                odf.subquestion = 'Please specify: '
                odf.has_subquestion = 1
            else
                odf.subquestion = nil
                odf.has_subquestion = 0
            end
            odf.column_number = 0
            odf.row_number = OutcomeDetailField.find_all_by_outcome_detail_id(od.id).length + 1
            odf.save
        else
            raise "Unable to match section for #{@question_type} type"
        end
    end
end

class MatrixRadioType < BaseType
    attr_reader :matrix_row, :matrix_row_code, :matrix_col, :matrix_col_value

    def initialize(row, extraction_form_id)
        super(row, extraction_form_id)
        @matrix_row = row[@@lookup['I']]
        @matrix_row_code = row[@@lookup['J']]
        @matrix_col = row[@@lookup['K']]
        @matrix_col_value = row[@@lookup['L']]
    end

    def build
        puts 'Will be building Matrix Radio type here.'
    end
end


class MatrixValueType < BaseType
    attr_reader :matrix_row, :matrix_row_code, :matrix_col, :matrix_col_code

    def initialize(row, extraction_form_id)
        super(row, extraction_form_id)
        @matrix_row = row[@@lookup['I']]
        @matrix_row_code = row[@@lookup['J']]
        @matrix_col = row[@@lookup['K']]
        @matrix_col_code = row[@@lookup['M']]
    end

    def build
        puts 'Will be building Matrix Value type here.'
    end
end

class RadioType < BaseType
    attr_reader :question_code, :answer_text, :answer_value

    def initialize(row, extraction_form_id)
        super(row, extraction_form_id)
        @question_code = row[@@lookup['E']]
        @answer_text = row[@@lookup['F']]
        @answer_value = row[@@lookup['G']]
    end

    def build
        case @section
        when 'design'
            unless DesignDetail.scoped_by_extraction_form_id(@extraction_form_id).exists?(question: @question_text)
                dd = DesignDetail.new
                dd.question = @question_text
                dd.extraction_form_id = @extraction_form_id
                dd.field_type = @question_type
                dd.field_note = nil
                dd.question_number = DesignDetail.find_all_by_extraction_form_id(@extraction_form_id).length + 1
                dd.study_id = nil
                dd.instruction = @instruction
                dd.is_matrix = 0
                dd.include_other_as_option = nil
                dd.save
            else
                dd = DesignDetail.scoped_by_extraction_form_id(@extraction_form_id).find_by_question(@question_text)
            end
            ddf = DesignDetailField.new
            ddf.design_detail_id = dd.id
            ddf.option_text = @answer_text
            ddf.subquestion = nil
            ddf.has_subquestion = 0
            ddf.column_number = 0
            ddf.row_number = DesignDetailField.find_all_by_design_detail_id(dd.id).length + 1
            ddf.save
        when 'outcome detail'
            unless OutcomeDetail.scoped_by_extraction_form_id(@extraction_form_id).exists?(question: @question_text)
                od = OutcomeDetail.new
                od.question = @question_text
                od.extraction_form_id = @extraction_form_id
                od.field_type = @question_type
                od.field_note = nil
                od.question_number = OutcomeDetail.find_all_by_extraction_form_id(@extraction_form_id).length + 1
                od.study_id = nil
                od.instruction = @instruction
                od.is_matrix = 0
                od.include_other_as_option = nil
                od.save
            else
                od = OutcomeDetail.scoped_by_extraction_form_id(@extraction_form_id).find_by_question(@question_text)
            end
            odf = OutcomeDetailField.new
            odf.outcome_detail_id = od.id
            odf.option_text = @answer_text
            odf.has_subquestion = 0
            odf.column_number = 0
            odf.row_number = OutcomeDetailField.find_all_by_outcome_detail_id(od.id).length + 1
            odf.save
        when 'quality'
            unless QualityDimensionField.scoped_by_extraction_form_id(@extraction_form_id).exists?(["title LIKE ?", "%#{@question_text}%"])
                qu = QualityDimensionField.new
                qu.title = @question_text
                qu.field_notes = ''
                qu.extraction_form_id = @extraction_form_id
                qu.study_id = nil
                qu.title = qu.title + " [#{@answer_text}]"
            else
                qu = QualityDimensionField.scoped_by_extraction_form_id(@extraction_form_id).find(:first, conditions: ["title LIKE ?", "%#{@question_text}%"])
                qu.title = qu.title[0..-2] + ",#{@answer_text}]"
            end
            qu.save
        else
            raise "Unable to match section for #{@question_type} type"
        end
    end
end

class TextType < BaseType
    attr_reader :question_code

    def initialize(row, extraction_form_id)
        super(row, extraction_form_id)
        @question_code = row[@@lookup['E']]
    end

    def build
        case @section
        when 'baseline characteristic'
            bc = BaselineCharacteristic.new
            bc.question = @question_text
            bc.field_type = @question_type
            bc.extraction_form_id = @extraction_form_id
            bc.field_notes = nil
            bc.question_number = BaselineCharacteristic.find_all_by_extraction_form_id(@extraction_form_id).length + 1
            bc.study_id = nil
            bc.instruction = @instruction
            bc.is_matrix = 0
            bc.include_other_as_option = nil
            bc.save
        when 'design'
            dd = DesignDetail.new
            dd.question = @question_text
            dd.extraction_form_id = @extraction_form_id
            dd.field_type = @question_type
            dd.field_note = nil
            dd.question_number = DesignDetail.find_all_by_extraction_form_id(@extraction_form_id).length + 1
            dd.study_id = nil
            dd.instruction = @instruction
            dd.is_matrix = 0
            dd.include_other_as_option = nil
            dd.save
        when 'publication'
            puts 'Found text type for publication section. We ignore this for now'
        else
            raise "Unable to match section for #{@question_type} type"
        end
    end
end
