## Require
require "logger"
require "rubyXL"

require_relative "helper"
require_relative "trollop"

translation_table = {
  "[Run-in period table][Value][Length]" => "r_length",
  "[Run-in period table][Value][Units]" => "r_unit",
  "[Run-in period table][Value][Placebo/Medication]" => "r_int",
  "[Run-in period table][Value][How used for randomization?]" => "r_random",
  "[Wash-out period table][Value1][Length]" => "w_length1",
  "[Wash-out period table][Value1][Units]" => "w_unit1",
  "[Wash-out period table][Value1][Placebo/Medication]" => "w_int1",
  "[Wash-out period table][Value1][How used for randomization?]" => "w_random1",
  "[Wash-out period table][Value2][Length]" => "w_length2",
  "[Wash-out period table][Value2][Units]" => "w_unit2",
  "[Wash-out period table][Value2][Placebo/Medication]" => "w_int2",
  "[Wash-out period table][Value2][How used for randomization?]" => "w_random2",
  "[What was the racial/ethnic population studied?][Caucasian]" => "white",
  "[What was the racial/ethnic population studied?][African Ancestry]" => "black",
  "[What was the racial/ethnic population studied?][Hispanic]" => "hispanic",
  "[What was the racial/ethnic population studied?][Asian/Pacific Islander]" => "asian",
  "[What was the racial/ethnic population studied?][Native American]" => "native",
  "[What was the racial/ethnic population studied?][Eskimo/Inuit]" => "eskimo",
  "[What was the racial/ethnic population studied?][Mixed]" => "mixed",
  "[What was the racial/ethnic population studied?][Other-Not otherwise specified]" => "race_oth_nos",
  "[What was the racial/ethnic population studied?][Race not reported]" => "race_nr",
  "[What were the cormorbidities reported in the study?][Anxiety]" => "co_anxiety",
  "[What were the cormorbidities reported in the study?][Dementia/severe geriatric agitation]" => "co_dementia",
  "[What were the cormorbidities reported in the study?][Depression]" => "co_depression",
  "[What were the cormorbidities reported in the study?][Insomnia]" => "co_insomnia",
  "[What were the cormorbidities reported in the study?][Obsessive-compulsive disorder]" => "co_ocd",
  "[What were the cormorbidities reported in the study?][Personality disorders (DSM IV)]" => "co_per_disorder",
  "[What were the cormorbidities reported in the study?][PTSD]" => "co_ptsd",
  "[What were the cormorbidities reported in the study?][Substance abuse]" => "co_sub_abuse",
  "[What were the cormorbidities reported in the study?][Eating disorder (incl. children 17 &amp; under)]" => "co_eat_disorder",
  "[What were the cormorbidities reported in the study?][ADHD (incl. children 17 &amp; under)]" => "co_adhd",
  "[What were the cormorbidities reported in the study?][Tourette's (incl. children 17 &amp; under)]" => "co_tourettes",
  "[What were reported for the following questions regarding subjects ages?][Mean Age][Value]" => "mean_age",
  "[What were reported for the following questions regarding subjects ages?][Median Age][Value]" => "median_age",
  "[What were reported for the following questions regarding subjects ages?][Age Range (upper limit)][Value]" => "age_range1",
  "[What were reported for the following questions regarding subjects ages?][Age Range (lower limit)][Value]" => "age_range2",
  "[Sample Size:][Screened][Value]" => "nscreen",
  "[Sample Size:][Eligible][Value]" => "neligible",
  "[Sample Size:][Withdrawn][Value]" => "nwithdraw",
  "[Sample Size:][Loss to follow-up][Value]" => "nloss",
  "[What was the percent of male participants?]" => "male",
  "[What was the study's setting?][Multi-center]" => "multi",
  "[What was the study's setting?][Single setting]" => "single",
  "[What was the study's setting?][Community practice]" => "community",
  "[What was the study's setting?][Long-term care facilities]" => "longterm",
  "[What was the study's setting?][VA Healthcare System]" => "va",
  "[What was the study's setting?][Other (study setting)]" => "setting_oth",
  "[What was the study's setting?][Setting not reported]" => "setting_nr",
  "[What was the study's funding source?][Government]" => "government",
  "[What was the study's funding source?][Hospital]" => "hospital",
  "[What was the study's funding source?][Industry]" => "industry",
  "[What was the study's funding source?][Private (non-industry)]" => "private",
  "[What was the study's funding source?][Other (funding source)]" => "funding_oth",
  "[What was the study's funding source?][Unclear]" => "funding_uncl",
  "[What was the study's funding source?][Funding not reported]" => "funding_nr",
  "[In what area was the study conducted?][US]" => "us",
  "[In what area was the study conducted?][Canada]" => "canada",
  "[In what area was the study conducted?][UK]" => "uk",
  "[In what area was the study conducted?][Western Europe]" => "europe",
  "[In what area was the study conducted?][Eastern Europe]" => "eastern_europe",
  "[In what area was the study conducted?][Australia/New Zealand]" => "australia_nz",
  "[In what area was the study conducted?][Asia]" => "asia",
  "[In what area was the study conducted?][Middle East]" => "middle_east",
  "[In what area was the study conducted?][Latin America]" => "latin_america",
  "[In what area was the study conducted?][Other Country]" => "other_country",
  "[In what area was the study conducted?][Country not reported]" => "country_nr",
  "[Treatment Allocation][Was the method of randomization adequate][Yes]" => "randapp",
  "[Treatment Allocation][Was the method of randomization adequate][No]" => "randapp",
  "[Treatment Allocation][Was the method of randomization adequate][Don't know]" => "randapp",
  "[Treatment Allocation][Was the treatment allocation conceled?][Yes]" => "conceal",
  "[Treatment Allocation][Was the treatment allocation conceled?][No]" => "conceal",
  "[Treatment Allocation][Was the treatment allocation conceled?][Don't know]" => "conceal",
  "[Is the study design trial with crossover?][Yes]" => "cross",
  "[Is the study design trial with crossover?][No]" => "cross",
  "[Did the article include a statement on the role of the funder?][Yes]" => "funder_role",
  "[Did the article include a statement on the role of the funder?][No]" => "funder_role",
  "[What were the study's inclusion criteria?]" => "inclusion_text",
  "[What were the study's exclusion criteria?]" => "exclusion_text",
  "[What was the method of adverse events assessment?][Monitored]" => "monitor",
  "[What was the method of adverse events assessment?][Elicited by investigator]" => "investigator",
  "[What was the method of adverse events assessment?][Reported spontaneously by patient]" => "patient",
  "[What was the method of adverse events assessment?][Medical record]" => "record",
  "[What was the method of adverse events assessment?][Other (method of assessment)]" => "ae_method_oth",
  "[What was the method of adverse events assessment?][Adverse event not reported]" => "ae_method_nr",
  "[What was the method of adverse events assessment?][Not applicable]" => "ae_method_na",
  "[Were stratified analysis reported on any of the following subgroups?][Age]" => "strat_age",
  "[Were stratified analysis reported on any of the following subgroups?][Gender]" => "strat_gender",
  "[Were stratified analysis reported on any of the following subgroups?][Race/Ethnicity]" => "strat_race",
  "[Were stratified analysis reported on any of the following subgroups?][Other (analysis reported)]" => "strat_other",
  "[Were stratified analysis reported on any of the following subgroups?][None of the above]" => "strat_noa",
  "[Outcomes][Is everyone followed up at the same time?][Yes]" => "Followup",
  "[Outcomes][Is everyone followed up at the same time?][No]" => "Followup",
  "[Outcomes][If no, is the follow-up time reported as a mean][Yes]" => "FollowupMean",
  "[Outcomes][If no, is the follow-up time reported as a mean][No]" => "FollowupMean",
  "[Were patients class-naive?][Yes]" => "class_naive",
  "[Were patients class-naive?][No]" => "class_naive",
  "[Were patients class-naive?][Don't know]" => "class_naive",
  "[[Drop-out rate questions:] Was the drop-out rate described and the reason given? [Yes,No,Don't know]]" => "dropouts2",
  "[[Drop-out rate questions:] Was the drop-out rate acceptable? [Yes,No,Don't know]]" => "dropoutacc",
  "[[Other sources of potential bias] Were co-interventions avoided or similar? [Yes,No,Don't know]]" => "bias_coints",
  "[[Other sources of potential bias] Was the compliance acceptable in all groups? [Yes,No,Don't know]]" => "bias_compliance",
  "[[Other sources of potential bias] Was the outcome assessment timing similar in all groups? [Yes,No,Don't know]]" => "bias_timing",
  "[Was the study described as randomized? [Yes,No]]" => "random",
  "[Were groups similar at baseline regarding the most important prognostic indicators? [Yes,No,Don't know]]" => "baseline1",
  "[Is the study described as: [Double blind,Single blind, patient,Single blind, outcome assessment,Single blind, not described,Open,Blinding not described,Not applicable]]" => "blind",
  "[If reported, was the method of double blinding appropriate? [Yes,No,Double blinding method not described,Not applicable]]" => "blindapp",
  "[Was the outcome assessor blinded? [Yes,No,Don't know]]" => "mask_assessor",
  "[Was the care provider blinded? [Yes,No,Don't know]]" => "mask_provider",
  "[Were patients blinded? [Yes,No,Don't know]]" => "mask_patient",
  "[Were all randomized participants analyzed in the group to which they were originally assigned? [Yes,No,Don't know]]" => "original",
}

## Minimal arg parser
## http://trollop.rubyforge.org/
opts = Trollop::options do
  opt :file,            "Filename",              :type => :string
  opt :log,             "Specify logging level", :type => :string, :default => "INFO"
  opt :project_id,      "Project ID",            :type => :integer
  opt :key_question_id, "Key Question ID",       :type => :integer
  opt :creator_id,      "Creator ID",            :type => :integer, :default => 1
  opt :dry_run,         "Dry-run. No database modifications take place"
  opt :analyze,         "Run the crawler and display statistical summary"
end

def set_up_logging(opts)
  log = Logger.new(STDOUT)
  opts[:log] = opts[:log].upcase
  case opts[:log]
  when "INFO"
    log.level = Logger::INFO
  when "DEBUG"
    log.level = Logger::DEBUG
  when "WARN"
    log.level = Logger::WARN
  end
  return log
end

def validate_arg_list(opts)
  Trollop::die :file,            "Missing file name"                 unless opts[:file_given]
  Trollop::die :project_id,      "You must supply a project id"      unless opts[:project_id_given]
  Trollop::die :key_question_id, "You are missing a key question id" unless opts[:key_question_id_given]
end

def display_options_parameters(opts)
  puts "File name: #{opts[:file]}"
  puts "Logging level: #{opts[:log]}"
  puts "Project ID: #{opts[:project_id]}"
  puts "Key question ID: #{opts[:key_question_id]}"
  puts "Creator ID: #{opts[:creator_id]}"
  puts "Dry run: #{opts[:dry_run]}"
  puts "Analyze: #{opts[:analyze]}"
end

def load_rails_environment
  ENV["RAILS_ENV"] = ARGV.first || ENV["RAILS_ENV"] || "development"
  require File.expand_path(File.dirname(__FILE__) + "./config/environment")
end

def load_study_data(file, log)
  workbook  = RubyXL::Parser.parse(file)
  worksheet = workbook[0]
  header = worksheet.extract_data[0]
  data = worksheet.extract_data[1..-2]
  log.debug "Study header has #{header.length} entries"
  log.debug "Study data has #{data.length} rows"
  return header, data
end

def get_extraction_forms_by_project_id(project_id)
  ExtractionForm.find_all_by_project_id(project_id)
end

def build_header_2_column_id_lookup_table(header_row)
  Hash[header_row.zip 0..header_row.length]
end

def create_misc_table_entries(ef_id, log)
  create_ef_section_option_entries(ef_id, log)
end

def create_ef_section_option_entries(ef_id, log)
  log.debug "Creating EF Section Option entry and Arm entries for extraction form ID #{ef_id}"
  EfSectionOption.create(
    :extraction_form_id => ef_id,
    :section            => "arm_detail",
    :by_arm             => 1,
    :by_outcome         => 0,
  )
  EfSectionOption.create(
    :extraction_form_id => ef_id,
    :section            => "outcome_detail",
    :by_arm             => 0,
    :by_outcome         => 1,
  )
end

def create_study_entries(project_id, creator_id, ef_id, log, dry_run)
  log.debug "Creating Study entry with project ID #{project_id}, creator ID #{creator_id}, extraction form ID #{ef_id}"
  Study.create(
    :project_id         => project_id,
    :creator_id         => creator_id,
    :extraction_form_id => ef_id,
  ) unless dry_run
end

def create_primary_publication_entries(study_id, internal_id, log, dry_run)
  log.debug "Creating Primary Publication entry with study ID #{study_id}"
  log.debug "Creating Primary Publication Internal ID #{internal_id}"
  pp = PrimaryPublication.create(
    :study_id    => study_id,
    :title       => nil,
    :author      => nil,
    :country     => nil,
    :year        => nil,
    :pmid        => nil,
    :journal     => nil,
    :volume      => nil,
    :issue       => nil,
    :trial_title => nil,
  ) unless dry_run
  PrimaryPublicationNumber.create(
    :primary_publication_id => pp.id,
    :number                 => internal_id,
    :number_type            => "internal",
  ) unless dry_run
end

def create_study_key_question_entries(ef_id, key_question_id, study_id, log, dry_run)
  log.debug "Creating Study Key Question entry with extraction form ID #{ef_id} and study ID #{study_id}"
  StudyKeyQuestion.create(
    :study_id => study_id,
    :key_question_id => key_question_id,
    :extraction_form_id => ef_id,
  ) unless dry_run
end

def create_study_extraction_form_entries(ef_id, study_id, log, dry_run)
  log.debug "Creating Study Extraction Form entry with extraction form ID #{ef_id} and study ID #{study_id}"
  StudyExtractionForm.create(
    :study_id => study_id,
    :extraction_form_id => ef_id,
  ) unless dry_run
end

def summarize_data(crawler, match_maker)
  puts "  ***************"
  puts " *** SUMMARY ***"
  puts "***************"
  puts ""
  puts "*** ERRORS ***"
  puts "Errors during crawling [#{crawler.error_stack.length}]:"
  crawler.error_stack.each do |crawl_error|
    p crawl_error
  end
  puts "Errors during match making [#{match_maker.error_stack.length}]:"
  match_maker.error_stack.each do |match_maker_error|
    p match_maker_error
  end
  #puts "****************************************************************************"
  #puts "****************************************************************************"
  #puts "*** WORK ORDERS ***"
  #puts "Work Order [#{crawler.work_order.length}]:"
  #crawler.work_order.each do |order|
  #  p order
  #end
  puts "****************************************************************************"
  puts "****************************************************************************"
  puts "*** SERVINGS ***"
  puts "Servings [#{match_maker.servings.length}]:"
  match_maker.servings.each do |serving|
    p serving
  end
  puts "****************************************************************************"
  puts "****************************************************************************"
end

class Crawler
  attr_reader :work_order, :error_stack

  def initialize(project_id, extraction_form_id, study_data_header, study_data_rows, log, header_2_column_id)
    @work_order         = Array.new
    @error_stack        = Array.new
    @project_id         = project_id
    @ef_id              = extraction_form_id
    @study_data_header  = study_data_header
    @study_data_rows    = study_data_rows
    @log                = log
    @header_2_column_id = header_2_column_id

    ## Entry point
    @log.info "Beginning crawling algorithm"

    ## Type detail tables are of the following type:
    #    - Arm Detail
    #    - Baseline Characteristic
    #    - Design Detail
    #    - Outcome Detail
    #    - Quality Dimension
    self.crawl_type_details_table

    ## Extraction form arms tables are tables declared in the extraction form
    #  question section and made available to pick from when extracting data from
    #  a study. However, they only offer choices and there is no other relationship
    #  between these and the study extraction, i.e. an entry here is not necessary
    #  for the study extraction, but it will aid in figuring out what fields to scan
    #  when it comes time to import the data
    self.crawl_extraction_form_arms_table

    ## Extraction form outcome names table is just like the extraction form arms table.
    self.crawl_extraction_form_outcome_names
  end

  def crawl_type_details_table
    ["ArmDetail", "BaselineCharacteristic", "DesignDetail", "OutcomeDetail", "QualityDimension"].each do |type|
      @log.info "Working on #{type} type"
      if type == "QualityDimension"
        type_detail_fields = "#{type}Field".constantize.find_all_by_extraction_form_id(@ef_id)
        type_detail_fields.each do |type_detail_field|
          temp = {:type                          => type,
                  :"#{type.underscore}_field_id" => type_detail_field.id,
                  :value                         => nil,
                  :notes                         => nil,
                  :study_id                      => nil,
                  :field_type                    => nil,
                  :extraction_form_id            => @ef_id,
                  :question_text                 => type_detail_field.title,
                  :lookup_text                   => "[#{type_detail_field.title}]",
          }
          @work_order.push(temp)
        end
      else
        type_details = "#{type}".constantize.find_all_by_extraction_form_id(@ef_id)
        type_details.each do |type_detail|
          ## "text" field_types are special in the sense that there is no entry for them in the type_detail_fields table.
          #  Therefore we cannot discover the count of these types by iterating through the number of entries in the
          #  type_detail_fields table, but must add an entry into the work_order array immediately
          if type_detail.field_type.downcase == "text"
            temp = {:type                          => type,
                    :"#{type.underscore}_field_id" => type_detail.id,
                    :value                         => nil,
                    :notes                         => nil,
                    :study_id                      => nil,
                    :extraction_form_id            => @ef_id,
                    :arm_id                        => nil,
                    :subquestion_value             => nil,
                    :row_field_id                  => 0,
                    :column_field_id               => 0,
                    :outcome_id                    => nil,
                    :question_text                 => type_detail.question,
                    :lookup_text                   => "[#{type_detail.question}]",
            }
            @work_order.push(temp)
          else
            type_detail_field_rows = "#{type}Field".constantize.find(:all, :conditions => {:"#{type.underscore}_id" => type_detail.id, :column_number => 0})
            type_detail_field_columns = "#{type}Field".constantize.find(:all, :conditions => {:"#{type.underscore}_id" => type_detail.id, :row_number => 0})
            type_detail_field_rows.each do |type_detail_field_row|
              ## If it is a matrix question we need to iterate through each column also
              if type_detail.is_matrix
                type_detail_field_columns.each do |type_detail_field_column|
                  temp = {:type                          => type,
                          :"#{type.underscore}_field_id" => type_detail.id,
                          :value                         => nil,
                          :notes                         => nil,
                          :study_id                      => nil,
                          :extraction_form_id            => @ef_id,
                          :arm_id                        => nil,
                          :subquestion_value             => nil,
                          :row_field_id                  => type_detail_field_row.id,     ## This refers to the id of the type detail field row
                          :column_field_id               => type_detail_field_column.id,  ## This refers to the id of the type detail field column
                          :outcome_id                    => nil,
                          :question_text                 => type_detail.question,
                          :option_text_row               => type_detail_field_row.option_text,
                          :option_text_column            => type_detail_field_column.option_text,
                          :lookup_text                   => "[#{type_detail.question}][#{type_detail_field_row.option_text}][#{type_detail_field_column.option_text}]",
                  }
                  @work_order.push(temp)
                end
              ## Otherwise just iterate through the rows
              else
              temp = {:type                          => type,
                      :"#{type.underscore}_field_id" => type_detail.id,
                      :value                         => nil,
                      :notes                         => nil,
                      :study_id                      => nil,
                      :extraction_form_id            => @ef_id,
                      :arm_id                        => nil,
                      :subquestion_value             => nil,
                      :row_field_id                  => 0,
                      :column_field_id               => 0,
                      :outcome_id                    => nil,
                      :question_text                 => type_detail.question,
                      :option_text_row               => type_detail_field_row.option_text,
                      :lookup_text                   => "[#{type_detail.question}][#{type_detail_field_row.option_text}]",
              }
              @work_order.push(temp)
              end  #if type_detail.is_matrix
            end  #type_detail_field_rows.each do |type_detail_field_row|
          end  #if type_detail.field_type.downcase == "text"
        end  #type_details.each do |type_detail|
      end  #if type == "QualityDimension"
    end  #["ArmDetail", "BaselineCharacteristic", "DesignDetail", "OutcomeDetail"].each do |type|
  end

  def crawl_extraction_form_arms_table
    # !!! TODO
  end

  def crawl_extraction_form_outcome_names
    # !!! TODO
  end
end

class MatchMaker
  attr_reader :error_stack, :servings

  def initialize(work_order, header_2_column_id, log, translation_table)
    @work_order        = work_order
    @header_hash       = header_2_column_id
    @log               = log
    @servings          = Array.new  ## This is going to be the updated work_order array
    @error_stack       = Array.new
    @translation_table = translation_table

    self.entry
  end

  def entry
    @work_order.each do |wo|
      ## Based on information in wo, find the corresponding study data header column id and add it to the work order
      add_header_column_id(wo)
    end
  end

  def add_header_column_id(wo)
    header_column_id = lookup(wo[:lookup_text])
    ## If lookup returns a match go ahead and add it to the @servings array
    if header_column_id
      wo.merge! :study_data_column_id => [header_column_id]
      @servings.push(wo)
    ## Otherwise we need to deal with the errors
    else
      if wo[:type] == "BaselineCharacteristic"
        _handle_stupid_baseline_characteristic_weirdo(wo)
      elsif wo[:type] == "ArmDetail"
        _handle_arm_detail_exceptions(wo)
      elsif wo[:type] == "OutcomeDetail"
        _handle_outcome_detail_exceptions(wo)
      else
        @error_stack.push(wo)
      end
    end
  end

  def _handle_stupid_baseline_characteristic_weirdo(wo)
    other_columns = ["como1", "como2", "como3", "como4", "como5", "como6", "como7", "como8", "como9", "como10", "como11", "como12", "como13"]
    other_column_id_array = Array.new
    other_columns.each do |other_column|
      column_id = @header_hash[other_column]
      other_column_id_array.push(column_id)
    end
    wo.merge! :study_data_column_id => other_column_id_array
    @servings.push(wo)
  end

  def _handle_arm_detail_exceptions(wo)
    ## Nothing we can do atm. Go ahead and append to @servings
    @servings.push(wo)
  end

  def _handle_outcome_detail_exceptions(wo)
    ## Nothing we can do atm. Go ahead and append to @servings
    @servings.push(wo)
  end

  def lookup(lookup_text)
    @header_hash[@translation_table[lookup_text]]
  end
end

class ServeDinner
  def initialize(ef_id, row, study_id, servings, header_2_column_id, log, dry_run, translation_table)
    @ef_id = ef_id
    @row = row
    @study_id = study_id
    @servings = servings
    @header_2_column_id = header_2_column_id
    @log = log
    @dry_run = dry_run
    @translation_table = translation_table

    self.entry
  end

  def entry
    ## Create all the arms for this study
    list_of_arms = create_arms_for_this_study

    ## Create all the outcomes for this study
    list_of_outcomes = create_outcomes_for_this_study

    #list_of_created_outcomes = self._insert_outcome_detail_final_followup(list_of_outcomes)
    ## TODO Picking the first outcome to represent all outcomes for the other outcome questions
    #  that do not specifically belong to an outcome

    @servings.each do |serving|
      case serving[:type]
      when "DesignDetail"
        @log.debug "Working on Design Detail data points"
        # Find value based on @translation_table
        column_header = @translation_table[serving[:lookup_text]]
        column_id = @header_2_column_id[column_header]
        value = @row[column_id]
        unless value == 0
          if value == 1
            value = serving[:option_text_row]
            if serving[:option_text_row].downcase.include? "other country"
              column_id_other = @header_2_column_id["other_country_sp"]
              subquestion_value = @row[column_id_other]
            end
          end
          self._insert_type_data_point(serving[:type], serving, value, subquestion_value, @study_id, nil, nil)
        end
      when "ArmDetail", "BaselineCharacteristic"
        ## For each arm use the templates from the servings to create an
        #  arm detail data point and baseline characteristic data point accordingly
        list_of_arms.each do |arm, n|
          arm_id = arm.id
          value = self._get_arm_detail_data_point_value(n, serving)
          if serving[:type] == "BaselineCharacteristic"
            arm_id = 0
          end
          unless value == 0
            if value == 1
              value = serving[:option_text_row]
            end
            self._insert_type_data_point(serving[:type], serving, value, @study_id, arm_id, 0)
          end
        end
      when "OutcomeDetail"
        list_of_outcomes.each do |outcome, n|
          outcome_id = outcome.id
          value = self._get_outcome_detail_data_point_value(n, serving)
          unless value == 0
            if value == 1
              value = serving[:option_text_row]
            end
            self._insert_type_data_point(serving[:type], serving, value, @study_id, 0, outcome_id)
          end
        end
        ## TODO outcome id is undetermined at this point. I do not know which outcome id to assign because
        #  these questions do no belong to any outcome arm
        #value = self._get_outcome_detail_data_point_value(serving)
        #unless value == 0
        #  if value == 1
        #    value = serving[:option_text_row]
        #  end
        #  self._insert_type_data_point(serving[:type], serving, value, @study_id, 0, outcome_id)
        #end
      when "QualityDimension"
        @log.debug "Working on Quality Dimension data points"
        column_header = @translation_table[serving[:lookup_text]]
        column_id = @header_2_column_id[column_header]
        value = @row[column_id]
        self._insert_type_data_point(serving[:type], serving, value, @study_id, nil, nil)
      end
    end
  end

  def _get_arm_detail_data_point_value(n, serving)
    lookup = {"[Arm Details][Arm information][N Entering]" => "nin_#{n}",
              "[Arm Details][Arm information][N Completing]" => "nout_#{n}",
              "[Arm Details][Arm information][Dose]" => "dose_#{n}",
              "[Arm Details][Arm information][Units]" => "doseunit_#{n}",
              "[Arm Details][Arm information][Frequency]" => "freq_#{n}",
              "[Arm Details][Arm information][Dose Description]" => "desc_#{n}",
              "[Arm Details][Arm information][Duration of treatment]" => "dur_#{n}",
              "[Arm Details][Arm information][Units (duration)]" => "durunit_#{n}",
              "[Run-in period table][Value][Length]" => "r_length",
              "[Run-in period table][Value][Units]" => "r_unit",
              "[Run-in period table][Value][Placebo/Medication]" => "r_int",
              "[Run-in period table][Value][How used for randomization?]" => "r_random",
              "[Wash-out period table][Value1][Length]" => "w_length1",
              "[Wash-out period table][Value1][Units]" => "w_unit1",
              "[Wash-out period table][Value1][Placebo/Medication]" => "w_int1",
              "[Wash-out period table][Value1][How used for randomization?]" => "w_random1",
              "[Wash-out period table][Value2][Length]" => "w_length2",
              "[Wash-out period table][Value2][Units]" => "w_unit2",
              "[Wash-out period table][Value2][Placebo/Medication]" => "w_int2",
              "[Wash-out period table][Value2][How used for randomization?]" => "w_random2",
              "[What was the racial/ethnic population studied?][Caucasian]" => "white",
              "[What was the racial/ethnic population studied?][African Ancestry]" => "black",
              "[What was the racial/ethnic population studied?][Hispanic]" => "hispanic",
              "[What was the racial/ethnic population studied?][Asian/Pacific Islander]" => "asian",
              "[What was the racial/ethnic population studied?][Native American]" => "native",
              "[What was the racial/ethnic population studied?][Eskimo/Inuit]" => "eskimo",
              "[What was the racial/ethnic population studied?][Mixed]" => "mixed",
              "[What was the racial/ethnic population studied?][Other-Not otherwise specified]" => "race_oth_nos",
              "[What was the racial/ethnic population studied?][Race not reported]" => "race_nr",
              "[What were the cormorbidities reported in the study?][Anxiety]" => "co_anxiety",
              "[What were the cormorbidities reported in the study?][Dementia/severe geriatric agitation]" => "co_dementia",
              "[What were the cormorbidities reported in the study?][Depression]" => "co_depression",
              "[What were the cormorbidities reported in the study?][Insomnia]" => "co_insomnia",
              "[What were the cormorbidities reported in the study?][Obsessive-compulsive disorder]" => "co_ocd",
              "[What were the cormorbidities reported in the study?][Personality disorders (DSM IV)]" => "co_per_disorder",
              "[What were the cormorbidities reported in the study?][PTSD]" => "co_ptsd",
              "[What were the cormorbidities reported in the study?][Substance abuse]" => "co_sub_abuse",
              "[What were the cormorbidities reported in the study?][Eating disorder (incl. children 17 &amp; under)]" => "co_eat_disorder",
              "[What were the cormorbidities reported in the study?][ADHD (incl. children 17 &amp; under)]" => "co_adhd",
              "[What were the cormorbidities reported in the study?][Tourette's (incl. children 17 &amp; under)]" => "co_tourettes",
              "[What were reported for the following questions regarding subjects ages?][Mean Age][Value]" => "mean_age",
              "[What were reported for the following questions regarding subjects ages?][Median Age][Value]" => "median_age",
              "[What were reported for the following questions regarding subjects ages?][Age Range (upper limit)][Value]" => "age_range1",
              "[What were reported for the following questions regarding subjects ages?][Age Range (lower limit)][Value]" => "age_range2",
              "[Sample Size:][Screened][Value]" => "nscreen",
              "[Sample Size:][Eligible][Value]" => "neligible",
              "[Sample Size:][Withdrawn][Value]" => "nwithdraw",
              "[Sample Size:][Loss to follow-up][Value]" => "nloss",
              "[What was the percent of male participants?]" => "male",
    }
    if serving[:lookup_text] == "[Arm Details][Arm information][Co-intervention(s)]"
      temp = @row[@header_2_column_id["coint_#{n}_1"]]
      value = temp.to_s
      (2..6).each do |cnt|
        temp = @row[@header_2_column_id["coint_#{n}_#{cnt}"]]
        value << ", #{temp.to_s}" unless temp.blank?
      end
    elsif serving[:lookup_text] == "[What were the cormorbidities reported in the study?][Other (cormorbities)]"
      temp = @row[@header_2_column_id["como1"]]
      value = temp.to_s
      (2..13).each do |cnt|
        temp = @row[@header_2_column_id["como#{cnt}"]]
        value << ", #{temp.to_s}" unless temp.blank?
      end
    #elsif serving[:lookup_text].include? "[What was the racial/ethnic population studied?]"
    #  value = serving[:option_text_row]
    #elsif serving[:lookup_text].include? "[What were the cormorbidities reported in the study?]"
    #  value = serving[:option_text_row]
    else
      value = @row[@header_2_column_id[lookup[serving[:lookup_text]]]]
    end
    return value
  end

  def _get_outcome_detail_data_point_value(n, serving)
    lookup = {
  "[What was the method of adverse events assessment?][Monitored]" => "monitor",
  "[What was the method of adverse events assessment?][Elicited by investigator]" => "investigator",
  "[What was the method of adverse events assessment?][Reported spontaneously by patient]" => "patient",
  "[What was the method of adverse events assessment?][Medical record]" => "record",
  "[What was the method of adverse events assessment?][Other (method of assessment)]" => "ae_method_oth",
  "[What was the method of adverse events assessment?][Adverse event not reported]" => "ae_method_nr",
  "[What was the method of adverse events assessment?][Not applicable]" => "ae_method_na",
  "[Were stratified analysis reported on any of the following subgroups?][Age]" => "strat_age",
  "[Were stratified analysis reported on any of the following subgroups?][Gender]" => "strat_gender",
  "[Were stratified analysis reported on any of the following subgroups?][Race/Ethnicity]" => "strat_race",
  "[Were stratified analysis reported on any of the following subgroups?][Other (analysis reported)]" => "strat_other",
  "[Were stratified analysis reported on any of the following subgroups?][None of the above]" => "strat_noa",
  "[Outcomes][Is everyone followed up at the same time?][Yes]" => "Followup",
  "[Outcomes][Is everyone followed up at the same time?][No]" => "Followup",
  "[Outcomes][If no, is the follow-up time reported as a mean][Yes]" => "FollowupMean",
  "[Outcomes][If no, is the follow-up time reported as a mean][No]" => "FollowupMean",
  "[Were patients class-naive?][Yes]" => "class_naive",
  "[Were patients class-naive?][No]" => "class_naive",
  "[Were patients class-naive?][Don't know]" => "class_naive",
  "[Outcome Text][Outcome Text][Value]" => "outcome#{n}",
  "[Outcome Text][Number][Value]" => "fup#{n}",
  "[Outcome Text][Unit][Value]" => "fupunit#{n}",
    }
    value = @row[@header_2_column_id[lookup[serving[:lookup_text]]]]
    return value
  end

  def create_arms_for_this_study
    ## !!! TODO: maybe check if arm exists and only create if necessary
    arm_choices = Array.new
    arm_list = Array.new
    extraction_form_arms = ExtractionFormArm.find_all_by_extraction_form_id(@ef_id)
    extraction_form_arms.each { |extraction_form_arm| arm_choices.push(extraction_form_arm.name) }
    (1..6).each do |n|
      arm_choices.each do |arm_choice|
        ## Determine if this study has this arm
        is_in_study = self._is_arm_in_study?(n, arm_choice)
        if is_in_study
          unless @dry_run
            arm = Arm.create(
              :study_id => @study_id,
              :title => arm_choice,
              :description => "",
              :display_number => Arm.find(:all, :conditions => {:study_id => @study_id, :extraction_form_id => @ef_id}).length + 1,
              :extraction_form_id => @ef_id,
              :is_suggested_by_admin => nil,
              :note => "",
              :efarm_id => nil,
              :default_num_enrolled => nil,
              :is_intention_to_treat => nil,
            )
            arm_list.push([arm, n])
          end
        end
      end
    end
    return arm_list
  end

  def create_outcomes_for_this_study
    outcome_choices = Array.new
    outcome_list = Array.new

    #general_outcome = Outcome.create(
    #  :study_id => @study_id,
    #  :title => "General",
    #  :is_primary => nil,
    #  :units => nil,
    #  :description => nil,
    #  :notes => nil,
    #  :outcome_type => nil,
    #  :extraction_form_id => @ef_id,
    #)
    #outcome_list.push([general_outcome, 0])
    ## Find all outcomes by extraction form id
    extraction_form_outcomes = ExtractionFormOutcomeName.find_all_by_extraction_form_id(@ef_id)
    extraction_form_outcomes.each { |extraction_form_outcome| outcome_choices.push(extraction_form_outcome.title) }
    (1..20).each do |n|
      outcome_choices.each do |outcome_choice|
        is_in_study = self._is_outcome_in_study?(n, outcome_choice)
        @log.debug "#{@row[0]} has outcomes: #{outcome_choice}" if is_in_study
        if is_in_study
          unless @dry_run
            outcome = Outcome.create(
              :study_id => @study_id,
              :title => outcome_choice,
              :is_primary => "1",
              :units => "",
              :description => "",
              :notes => "",
              :outcome_type => "Time to Event",
              :extraction_form_id => @ef_id,
            )
            outcome_list.push([outcome, n])
          end
        end
      end
    end
    return outcome_list
  end

  def _is_arm_in_study?(n, arm_choice)
    column_id = @header_2_column_id[translate_arm_names(n, arm_choice)]
    @row[column_id] == 1 unless column_id.nil?
  end

  def _is_outcome_in_study?(n, outcome_choice)
    column_id = @header_2_column_id["outcome#{n}"]
    value = @row[column_id]
    value == outcome_choice
  end

  def translate_arm_names(n, arm_choice)
    lookup = {
      "Placebo" => "int_#{n}_1",
      "Aripiprazole" => "int_#{n}_2",
      "Asenapine" => "int_#{n}_3",
      "Iloperidone" => "int_#{n}_4",
      "Olanzapine" => "int_#{n}_5",
      "Quetiapine" => "int_#{n}_6",
      "Paliperidone" => "int_#{n}_7",
      "Risperidone" => "int_#{n}_8",
      "Ziprasidone" => "int_#{n}_9",
      "Ziprasidone" => "int_#{n}_9",
      "Other" => "int_#{n}_10",
    }
    lookup[arm_choice]
  end

  def _insert_type_data_point(type, serving, value, subquestion_value="", study_id, arm_id, outcome_id)
    serving[:arm_id] = arm_id
    serving[:outcome_id] = outcome_id
    if type == "QualityDimension"
      prev = "#{type}DataPoint".constantize.find(:first, :conditions => {:"#{type.underscore}_field_id" => serving[:"#{type.underscore}_field_id"],
                                                                         :value                         => value,
                                                                         :notes                         => nil,
                                                                         :study_id                      => study_id,
                                                                         :field_type                    => nil,
                                                                         :extraction_form_id            => serving[:extraction_form_id],
      })
      "#{type}DataPoint".constantize.create(
        :"#{type.underscore}_field_id" => serving[:"#{type.underscore}_field_id"],
        :value                         => value,
        :notes                         => nil,
        :study_id                      => study_id,
        :field_type                    => nil,
        :extraction_form_id            => serving[:extraction_form_id],
      ) unless prev
    else
      prev = "#{type}DataPoint".constantize.find(:first, :conditions => {:"#{type.underscore}_field_id" => serving[:"#{type.underscore}_field_id"],
                                                                         :value                         => value,
                                                                         :notes                         => nil,
                                                                         :study_id                      => study_id,
                                                                         :extraction_form_id            => serving[:extraction_form_id],
                                                                         :arm_id                        => arm_id,
                                                                         :subquestion_value             => subquestion_value,
                                                                         :row_field_id                  => serving[:row_field_id],
                                                                         #:column_field_id               => serving[:column_field_id],
                                                                         :outcome_id                    => serving[:outcome_id],
      })
      "#{type}DataPoint".constantize.create(
        :"#{type.underscore}_field_id" => serving[:"#{type.underscore}_field_id"],
        :value                         => value,
        :notes                         => nil,
        :study_id                      => study_id,
        :extraction_form_id            => serving[:extraction_form_id],
        :arm_id                        => serving[:arm_id],
        :subquestion_value             => subquestion_value,
        :row_field_id                  => serving[:row_field_id],
        :column_field_id               => serving[:column_field_id],
        :outcome_id                    => serving[:outcome_id],
      ) unless prev
    end
  end

  def _insert_outcome_detail_final_followup(list_of_outcomes, outcome_detail_field_id)
    list_of_created_outcomes = Array.new
    list_of_outcomes.each do |outcome, n|
      (1..20).each do |cnt|
        if @row[@header_2_column_id["outcome#{cnt}"]] == outcome.title
          new_outcome = Outcome.create(
            :study_id => @study_id,
            :title => outcome.title,
            :is_primary => nil,
            :units => @row[@header_2_column_id["fupunit#{n}"]],
            :description => nil,
            :notes => nil,
            :outcome_type => nil,
            :extraction_form_id => @ef_id,
          )
          OutcomeDetailDataPoint.create(
            :outcome_detail_field_id => outcome_detail_field_id,
            :value => outcome.title,
            :notes => nil,
            :study_id => @study_id,
            :extraction_form_id => @ef_id,
            :subquestion_value => nil,
            :row_field_id => nil,
            :column_field_id => nil,
            :arm_id => 0,
            :outcome_id => new_outcome.id,
          )
          list_of_created_outcomes.push(new_outcome)
        end
      end
    end
    return list_of_created_outcomes
  end
end






if __FILE__ == $0
  validate_arg_list(opts)
  log = set_up_logging(opts)
  log.info "Program started"
  display_options_parameters(opts) if opts[:log] == "DEBUG"
  log.info "Loading rails environment..please hold.."
  load_rails_environment
  log.info "Rails environment has been loaded"

  ## Separate header from the data
  log.info "Loading study data"
  study_data_header, study_data_rows = load_study_data(opts[:file], log)

  ## Column header -> Column ID mapping
  header_2_column_id = build_header_2_column_id_lookup_table(study_data_header)

  log.info "..done!"
  log.debug "Finding all extraction forms related to project with ID #{opts[:project_id]}"
  extraction_forms = get_extraction_forms_by_project_id(opts[:project_id])

  ## Iterate through each extraction form that is part of the given project id
  extraction_forms.each do |ef|
    crawler     = Crawler.new(opts[:project_id], ef.id, study_data_header, study_data_rows, log, header_2_column_id)
    match_maker = MatchMaker.new(crawler.work_order, header_2_column_id, log, translation_table)

    ## We may be in analysis mode where we are checking for errors first and display a statistical summary
    #  of the data we are dealing with
    if opts[:analyze]
      summarize_data(crawler, match_maker)
    else
      ## !!! WARNING: Creating misc. table entries will require manual adjustment, specifically for the Extraction Form Arm table
      create_misc_table_entries(ef.id, log) unless opts[:dry_run]

      ## Iterate through each study entry in the study data
      study_data_rows.each do |row|

        ## Fetch internal ID so we can differentiate studies.
        internal_id = row[header_2_column_id["id"]]
        log.debug "Current study has the following internal ID [#{internal_id}]"

        ## Create a new study in the db
        study = create_study_entries(opts[:project_id], opts[:creator_id], ef.id, log, opts[:dry_run])
        study_id = study.id unless opts[:dry_run]
        study_id = 0 if opts[:dry_run]

        ## Insert publication information. We only have internal ID's to differentiate each study with
        create_primary_publication_entries(study_id, internal_id, log, opts[:dry_run])

        ## Add table entries for many-to-many relationships of key questions to studies
        #  and extraction forms to studies
        create_study_key_question_entries(ef.id, opts[:key_question_id], study_id, log, opts[:dry_run])
        create_study_extraction_form_entries(ef.id, study_id, log, opts[:dry_run])

        ## Iterate through the work order list and create db entries
        ServeDinner.new(ef.id, row, study_id, match_maker.servings, header_2_column_id, log, opts[:dry_run], translation_table)
      end
    end
  end
end


