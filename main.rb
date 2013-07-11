require "rubyXL"
require_relative "helper"
require_relative "question_type"

# Extraction Form file
ef_file = "data/nira.xlsx"
# Study Data file
sd_file = "data/ap2dataout.xlsx"

puts "INFO: Program started.."
puts "INFO: Loading rails environment..please hold.."

ENV["RAILS_ENV"] = ARGV.first || ENV["RAILS_ENV"] || "development"
require File.expand_path(File.dirname(__FILE__) + "./SRDR/config/environment")

puts "INFO: Rails environment has been loaded."
puts "INFO: Building project.."


# Instantiate project.
project_title = "Autoimport Test Run 1"
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
ef_is_ready = 1
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
    put "CRITICAL: Unable to save extraction form to database."
end


# Associate extraction form with keyquestion
extraction_form_key_question = ExtractionFormKeyQuestion.new(
        extraction_form_id: extraction_form.id,
        key_question_id: key_question.id)

if extraction_form_key_question.valid?
    puts "INFO: Saving new extraction form key question association to database returned [" +
        green(extraction_form_key_question.save.to_s) + "]"
else
    put "CRITICAL: Unable to save extraction form to database."
end


# Create entries in extraction_form_sections table.
# This is required for all the extraction form tabs to work correctly.
extraction_form_section_list = ['questions', 'publications', 'arms',
        'arm_details', 'design', 'baselines', 'outcomes', 'outcome_details',
        'results', 'adverse', 'quality']
extraction_form_section_list.each do |section|
    extraction_form_section = ExtractionFormSection.create(
            extraction_form_id: extraction_form.id,
            section_name: section,
            included: 1
    )
    if ['questions', 'publications'].include? section
        extraction_form_section.included = 0
        extraction_form_section.save
    end
end

# Create Arms
["Placebo", "Aripiprazole", "Asenapine", "Iloperidone", "Olanzapine", "Quetiapine", "Paliperidone", "Risperidone", "Ziprasidone", "Other"].each do |n|
    ExtractionFormArm.create(
        :name               => n,
        :description        => "",
        :note               => nil,
        :extraction_form_id => extraction_form.id,
    )
end

_outcome_detail = OutcomeDetail.create(
    :question => "Outcome Text",
    :extraction_form_id => extraction_form.id,
    :field_type => "matrix_select",
    :field_note => nil,
    :question_number => OutcomeDetail.find_all_by_extraction_form_id(extraction_form.id).length + 1,
    :study_id => nil,
    :is_matrix => 1,
)

OutcomeDetailField.create(
    :outcome_detail_id => _outcome_detail.id,
    :option_text => "Outcome Text",
    :column_number => 0,
    :row_number => 1,
)
OutcomeDetailField.create(
    :outcome_detail_id => _outcome_detail.id,
    :option_text => "Number",
    :column_number => 0,
    :row_number => 2,
)
OutcomeDetailField.create(
    :outcome_detail_id => _outcome_detail.id,
    :option_text => "Unit",
    :column_number => 0,
    :row_number => 3,
)
OutcomeDetailField.create(
    :outcome_detail_id => _outcome_detail.id,
    :option_text => "Value",
    :column_number => 1,
    :row_number => 0,
)

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

# Open up extraction form information file
workbook = RubyXL::Parser.parse(ef_file)
ws1 = workbook[0]
ws2 = workbook[1]

# Prune the data - in case we have a header row.
if ws1.extract_data[0][0] == "Section"
    data1 = ws1.extract_data[1..-1]
else
    data1 = ws1.extract_data
end

if ws2.extract_data[0][0] == "SRDR tab"
    data2 = ws2.extract_data[1..-1]
else
    data2 = ws2.extract_data
end

## Scan the data worksheet and determine how many outcomes exist
workbook  = RubyXL::Parser.parse(sd_file)
worksheet = workbook[0]
header = worksheet.extract_data[0]
data = worksheet.extract_data[1..-2]
header_lookup = Hash[header.zip 0..header.length]
outcome_list = Array.new
data.each do |row|
    (1..20).each do |n|
        outcome = row[header_lookup["outcome#{n}"]]
        outcome_list.push(outcome) unless outcome.blank?
    end
end
outcome_set = outcome_list.to_set
outcome_set.each do |outcome|
    ExtractionFormOutcomeName.create(
        :title => outcome,
        :note => "",
        :extraction_form_id => extraction_form.id,
        :outcome_type => "Time to Event",
    )
end


# Begin information extraction
data1.to_enum.with_index(0).each do |row, i|
    case row[lookup['D']]
    when 'checkbox'
        object = CheckboxType.new(row, extraction_form.id)
    when 'matrix_radio'
        object = MatrixRadioType.new(row, extraction_form.id)
    when 'matrix_select'
        object = MatrixSelectType.new(row, extraction_form.id)
    when 'radio'
        object = RadioType.new(row, extraction_form.id)
    when 'text'
        object = TextType.new(row, extraction_form.id)
    else
        raise 'Unable to match question type'
    end
    # Execute build method for respective question type. The build method is
    # where the data passed to the object constructor is converted to values
    # to be inserted into the database depending on the section type.
    # Each object is responsible for its own implementation which should make
    # it easy to switch in and out different extraction format forms.
    object.build
end


