require "rubyXL"
require "/home/sunya7a/Hive/Rails/SRDR/ImportProject/helper"

puts "INFO: Program started.."
puts "INFO: Loading rails environment..please hold.."

ENV["RAILS_ENV"] = ARGV.first || ENV["RAILS_ENV"] || "development"
require File.expand_path(File.dirname(__FILE__) + "./config/environment")

puts "INFO: Rails environment has been loaded."
puts "INFO: Building project.."

# Instantiate project.
project_title = "Autoimport 1"
project_description = "Autoimport 1 description"
project_notes = "Autoimport 1 notes"
project_funding_source = "Autoimport 1 funding source"
project_creator_id = 1  # admin id
project_is_public = 0  # not public
project_contributors = "Autoimport 1 import tool"
project_methodology = "Automated import tool"

project = Project.new(
        title: project_title,
        description: project_description,
        notes: project_notes,
        funding_source: project_funding_source,
        creator_id: project_creator_id,
        is_public: project_is_public,
        contributors: project_contributors,
        methodology: project_methodology)

if project.valid?
    puts "INFO: Saving new project to database returned [" +
        green(project.save.to_s) + "]"
else
    puts "CRITICAL: Unable to save new project to database."
end


# Associate key question with project
kq_project_id = project.id
kq_question_number = KeyQuestion.where(project_id: kq_project_id).length + 1
kq_question = "Why is the world round?"

key_question = KeyQuestion.new(
        project_id: kq_project_id,
        question_number: kq_question_number,
        question: kq_question)

if key_question.valid?
    puts "INFO: Saving new key question to database returned [" +
        green(key_question.save.to_s) + "]"
else
    puts "CRITICAL: Unable to save key question to database."
end


# Associate extraction form with project
ef_title = "Autoimport 1 EF title"
ef_creator_id = project_creator_id
ef_notes = "Autoimport 1 EF notes"
ef_adverse_event_display_arms = 1
ef_adverse_event_display_total = 1
ef_project_id = project.id
ef_is_ready = 0
ef_bank_id = nil
ef_is_diagnostic = 0

extraction_form = ExtractionForm.new(
        title: ef_title,
        creator_id: ef_creator_id,
        notes: ef_notes,
        adverse_event_display_arms: ef_adverse_event_display_arms,
        adverse_event_display_total: ef_adverse_event_display_total,
        project_id: ef_project_id,
        is_ready: ef_is_ready,
        bank_id: ef_bank_id,
        is_diagnostic: ef_is_diagnostic)

if extraction_form.valid?
    puts "INFO: Saving new extraction form to database returned [" +
        green(extraction_form.save.to_s) + "]"
else
    puts "CRITICAL: Unable to save extraction form to database."
end


# Column map
array = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
         'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
         'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AK', 'AL',
         'AM', 'AN', 'AO', 'AP', 'AQ', 'AR', 'AS', 'AT', 'AU', 'AV', 'AW', 'AX',
         'AY', 'AZ',
         'BA', 'BB', 'BC', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI', 'BJ', 'BK', 'BL',
         'BM', 'BN', 'BO', 'BP', 'BQ', 'BR', 'BS', 'BT', 'BU', 'BV', 'BW', 'BX',
         'BY', 'BZ',
         'CA', 'CB', 'CC', 'CD', 'CE', 'CF', 'CG', 'CH', 'CI', 'CJ', 'CK', 'CL',
         'CM', 'CN', 'CO', 'CP', 'CQ', 'CR', 'CS', 'CT', 'CU', 'CV', 'CW', 'CX',
         'CY', 'CZ',
         'DA', 'DB', 'DC', 'DD', 'DE', 'DF', 'DG', 'DH', 'DI', 'DJ', 'DK', 'DL',
         'DM', 'DN', 'DO', 'DP', 'DQ', 'DR', 'DS', 'DT', 'DU', 'DV', 'DW', 'DX',
         'DY', 'DZ',
         'EA', 'EB', 'EC', 'ED', 'EE', 'EF', 'EG', 'EH', 'EI', 'EJ', 'EK', 'EL',
         'EM', 'EN', 'EO', 'EP', 'EQ', 'ER', 'ES', 'ET', 'EU', 'EV', 'EW', 'EX',
         'EY', 'EZ',
         'FA', 'FB', 'FC', 'FD', 'FE', 'FF', 'FG', 'FH', 'FI', 'FJ', 'FK', 'FL',
         'FM', 'FN', 'FO', 'FP', 'FQ', 'FR', 'FS', 'FT', 'FU', 'FV', 'FW', 'FX',
         'FY', 'FZ',
]

# Build lookup table for easier column access
lookup = Hash[array.zip 0..array.length]
lookup = { 'A' => 0,      # Section
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

# Open up extraction form information file
file = "autoimport/nira.xlsx"
workbook = RubyXL::Parser.parse(file)
ws1 = workbook[0]
ws2 = workbook[1]

# Prune the data - in case we have a header row.
if ws1.extract_data[0][0] == 'Section'
    data = ws1.extract_data[1..-1]
else
    data = ws1.extract_data
end

# last_question_number is being to help determine whether we are moving on to a new question
# TODO: We really should be checking if there is an extraction form (ef) object with the
#       same question number. If so then add to it, else create a new one.
last_question_number = 'NA'
question = nil
extraction_form_item_stack = Array.new

# Begin information extraction
data.to_enum.with_index(0).each do |row, i|
    if last_question_number != row[lookup['B']]
        last_question_number = row[lookup['B']]
        extraction_form_item_stack.push(question) unless question.nil?
        question = QuestionType.new(
            section         = row[lookup['A']],
            question_number = row[lookup['B']],
            question_text   = row[lookup['C']],
            question_type   = row[lookup['D']],
            question_code   = [row[lookup['E']]],
            answ_text       = [row[lookup['F']]],
            answ_value      = [row[lookup['G']]],
            answ_code       = [row[lookup['H']]],
            matrix_row      = [row[lookup['I']]],
            matrix_row_code = [row[lookup['J']]],
            matrix_col      = [row[lookup['K']]],
            matrix_col_val  = [row[lookup['L']]],
            matrix_col_code = [row[lookup['M']]],
            instruction     = [row[lookup['N']]],
        )
    else
        question.question_code.push(row[lookup['E']])
        question.answ_text.push(row[lookup['F']])
        question.answ_value.push(row[lookup['G']])
        question.answ_code.push(row[lookup['H']])
        question.matrix_row.push(row[lookup['I']])
        question.matrix_row_code.push(row[lookup['J']])
        question.matrix_col.push(row[lookup['K']])
        question.matrix_col_val.push(row[lookup['L']])
        question.matrix_col_code.push(row[lookup['M']])
        question.instruction.push(row[lookup['N']])
    end
end




puts ""
puts " ---- DETAILED SUMMARY ---- "
puts ""
puts project.inspect
puts ""
puts key_question.inspect
puts ""
puts extraction_form.inspect
puts ""
puts extraction_form_item_stack.inspect
