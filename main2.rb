require "rubyXL"
require_relative "helper"

# TODO: remove this constant when finished
project_id = 13
key_question_id = 13
creator_id = 1

# Extraction form information filename
ef_filename = "data/nira.xlsx"

# Study Data filename
sd_filename = "data/ap2dataout.xlsx"

class Crawler

    @@ROW_COUNTER = 0

    def initialize(project_id, ef_filename, sd_filename)
        @work_order = Array.new
        @error_stack = Array.new

        puts "INFO: Program started.."
        puts "INFO: Loading rails environment..please hold.."
        ENV["RAILS_ENV"] = ARGV.first || ENV["RAILS_ENV"] || "development"
        require File.expand_path(File.dirname(__FILE__) + "./config/environment")
        puts "INFO: Rails environment has been loaded."

        @project = self._get_project_by_id(project_id)

        workbook_ef = RubyXL::Parser.parse(ef_filename)
        workbook_sd = RubyXL::Parser.parse(sd_filename)

        ef_ws1 = workbook_ef[0]
        ef_ws2 = workbook_ef[1]
        sd_ws1 = workbook_sd[0]

        @data_ef1 = ef_ws1.extract_data[1..-1]
        @data_ef2 = ef_ws2.extract_data[1..-1]
        @data_sd_header = sd_ws1.extract_data[0]
        @data_sd1 = sd_ws1.extract_data[1..-1]

        self._get_current_study_data_row()
    end

    def _get_current_study_data_row
        @row = self.get_study_data_row()
    end

    def _get_column_id(column_name)
        header_lookup = Hash[@data_sd_header.zip 0..@data_sd_header.length]
        header_lookup[column_name]
    end

    def _get_cell_value(column_id)
        @row[column_id]
    end

    def _push_arm_details(ef, ad, i, j, value, column_field_id, row_field_id)
        temp = {:section => "Arm Detail Arm",
                :type => "arm table",
                :extraction_form => ef,
                :arm_detail => ad,
                :i => i,
                :j => j,
                :value => value,
                :column_field_id => column_field_id,
                :row_field_id => row_field_id
        }
        @work_order.push(temp)
    end

    def crawl_arm_detail_answer_columns(ef)
        arm_details = self.arm_details(ef)
        arm_details.each do |ad|
            if ad.question.downcase.include? "arm details"
                (1..6).each do |i|
                    (1..10).each do |j|
                        header_lookup = Hash[@data_sd_header.zip 0..@data_sd_header.length]
                        header_name = "int_" + i.to_s + "_" + j.to_s
                        column_nr = header_lookup[header_name]
                        #puts "+++++++++++++++++++++++++++++++++++++++++++++++++"
                        #puts "+++++++++++++++++++++++++++++++++++++++++++++++++"
                        #puts "#{header_name} found in column number #{column_nr}"
                        value = @row[column_nr]
                        unless ( value == 0 || value.blank?)
                            # Build the column header
                            cell_value = String.new
                            rows = ArmDetailField.find(:all, :conditions => {:arm_detail_id => ad.id,
                                                                             :column_number => 0})
                            rows.each do |row|
                                columns = ArmDetailField.find(:all, :conditions => {:arm_detail_id => ad.id,
                                                                                    :row_number => 0})
                                columns.each do |column|
                                    lookup_arms = {"N Entering" => "nin_#{i}",
                                                   "N Completing" => "nout_#{i}",
                                                   "Dose" => "dose_#{i}",
                                                   "Units" => "doseunit_#{i}",
                                                   "Frequency" => "freq_#{i}",
                                                   "Dose Description" => "desc_#{i}",
                                                   "Duration of treatment" => "durunit_#{i}",
                                    }
                                    if column.option_text.downcase.include? "intervention"
                                        (1..6).each do |cnt|
                                            #puts "co-intervention values: #{cell_value}"
                                            #puts "coint_#{i}_#{cnt}"
                                            #puts header_lookup["coint_#{i}_#{cnt}"]
                                            #puts @row[header_lookup["coint_#{i}_#{cnt}"]]
                                            temp = @row[header_lookup["coint_#{i}_#{cnt}"]].to_s
                                            cell_value << ", #{temp}" unless temp.blank?
                                        end
                                    else
                                        cell_value = @row[header_lookup[lookup_arms[column.option_text]]].to_s
                                        #puts "arm values: #{cell_value}"
                                    end
                                    column_field_id = column.id
                                    row_field_id = row.id
                                    self._push_arm_details(ef, ad, i, j, cell_value, column_field_id, row_field_id)
                                end
                            end
                        end
                    end
                end
            else
                case ad.field_type
                when "matrix_select"
                    arm_detail_fields = self.arm_detail_fields(ad)
                    arm_detail_fields.each do |adf|
                        if adf.column_number == 0
                            # Get arm detail fields columns
                            arm_detail_field_columns = self._get_arm_detail_field_columns(ad)
                            arm_detail_field_columns.each do |adfc|
                                column_nr= self.lookup_arm_detail(ad, adf, adfc.option_text)
                                if column_nr.blank?
                                    self._log_error(ad, adf)
                                else
                                    self._push_addp_matrix_select(ef, ad, adf, adfc, @row[column_nr])
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    def _get_project_by_id(project_id)
        Project.find_by_id(project_id)
    end

    def extraction_forms()
        self._get_extraction_forms()
    end

    def _get_extraction_forms()
        ExtractionForm.find_all_by_project_id(@project.id)
    end

    def key_questions()
        self._get_key_questions()
    end

    def _get_key_questions()
        KeyQuestion.find_all_by_project_id(@project.id)
    end

    def design_details(ef)
        ef_id = ef.id
        self._get_design_details(ef_id)
    end

    def _get_design_details(extraction_form_id)
        DesignDetail.find_all_by_extraction_form_id(extraction_form_id)
    end

    def design_detail_fields(design_detail)
        design_detail_id = design_detail.id
        self._get_design_detail_fields(design_detail_id)
    end

    def _get_design_detail_fields(design_detail_id)
        DesignDetailField.find_all_by_design_detail_id(design_detail_id)
    end

    def arm_details(ef)
        ef_id = ef.id
        self._get_arm_details(ef_id)
    end

    def outcome_details(ef)
        ef_id = ef.id
        self._get_outcome_details(ef_id)
    end

    def _get_outcome_details(extraction_form_id)
        OutcomeDetail.find_all_by_extraction_form_id(extraction_form_id)
    end

    def _get_arm_details(extraction_form_id)
        ArmDetail.find_all_by_extraction_form_id(extraction_form_id)
    end

    def arm_detail_fields(arm_detail)
        arm_detail_id = arm_detail.id
        self._get_arm_detail_fields(arm_detail_id)
    end

    def outcome_detail_fields(outcome_detail)
        outcome_detail_id = outcome_detail.id
        self._get_outcome_detail_fields(outcome_detail_id)
    end

    def _get_outcome_detail_fields(outcome_detail_id)
        OutcomeDetailField.find_all_by_outcome_detail_id(outcome_detail_id)
    end

    def _get_arm_detail_fields(arm_detail_id)
        ArmDetailField.find_all_by_arm_detail_id(arm_detail_id)
    end

    def get_study_data_row()
        @data_sd1[@@ROW_COUNTER]
    end

    def increment_row_counter()
        @@ROW_COUNTER += 1
    end

    def crawl_baseline_characteristic_answer_columns(ef)
        baseline_characteristics = BaselineCharacteristic.find(:all, :conditions => {:extraction_form_id => ef.id})
        baseline_characteristics.each do |bc|
            case bc.field_type
            when "checkbox"
                baseline_characteristic_fields = BaselineCharacteristicField.find(:all, :conditions => {:baseline_characteristic_id => bc.id})
                baseline_characteristic_fields.each do |bcf|
                    if bcf.option_text.downcase.include? "other"
                        self._push_bcdp_checkbox_other(ef, bc, bcf)
                        next
                    end
                    column_nr = lookup(bcf.option_text)
                    if column_nr.blank?
                        self._log_error(bc, bcf)
                    elsif @row[column_nr] == 1
                        self._push_bcdp_checkbox(ef, bc, bcf)
                    elsif @row[column_nr] == 0
                        pass
                        #puts "Nothing to do here #{bcf.option_text}"
                    else
                        self._log_error(bc, bcf)
                    end
                end
            when "matrix_select"
                baseline_characteristic_fields = BaselineCharacteristicField.find(:all, :conditions => {:baseline_characteristic_id => bc.id})
                baseline_characteristic_fields.each do |bcf|
                    if bcf.column_number == 0
                        column_nr = lookup(bcf.option_text)
                        if column_nr.blank?
                            self._log_error(bc, bcf)
                        else
                            value = @row[column_nr]
                            value = self._translate_age_value(value)
                            self._push_bcdp_matrix_select(ef, bc, bcf, value)
                        end
                    end
                end
            when "text"
                value = @row[lookup(bc.question)]
                self._push_bcdp_text(ef, bc, value)
            end
        end
    end

    def crawl_quality_dimension_answer_columns(ef)
        quality_dimension_fields = QualityDimensionField.find(:all, :conditions => {:extraction_form_id => ef.id})
        quality_dimension_fields.each do |qdf|
            column_nr = lookup(qdf.title)
            value = @row[column_nr]
            if qdf.title.downcase.include? "is the study described as"
                value = self._convert_special_case1(value)
            elsif qdf.title.downcase.include? "if reported, was the method of double"
                value = self._convert_special_case2(value)
            else
                value = self._convert_yes_no_dontknow(value)
            end
            self._push_quality_dimension(ef, qdf, value)
        end
    end

    def _convert_special_case1(value)
        convert = {1 => "Double blind",
                   2 => "Single blind, patient",
                   3 => "Single blind, outcome assessment",
                   4 => "Single blind, not described",
                   5 => "Open",
                   8 => "Blinding not described",
                   9 => "Not applicable"
        }
        convert[value]
    end

    def _convert_special_case2(value)
        convert = {1 => "Yes",
                   2 => "No",
                   8 => "Double blinding method not described",
                   9 => "Not applicable"
        }
        convert[value]
    end

    def _push_quality_dimension(ef, qdf, value)
        temp = {:section => "Quality Dimension",
                :quality_dimension_field => qdf,
                :value => value
        }
        @work_order.push(temp)
    end

    def _convert_yes_no_dontknow(value)
        if value == 1
            return "Yes"
        elsif value == 2
            return "No"
        else
            return "Don't know"
        end
    end

    def _push_bcdp_matrix_select(ef, bc, bcf, value)
        temp = {:section => "Baseline characteristic",
                :type => "Matrix_select",
                :extraction_form => ef,
                :baseline_characteristic => bc,
                :baseline_characteristic_fields => bcf,
                :value => value
        }
        @work_order.push(temp)
    end

    def _translate_age_value(value)
        if value == 999
            return "Not reported"
        else
            return value.to_s
        end
    end

    def _push_bcdp_text(ef, bc, value)
        temp = {:section => "Baseline characteristic",
                :type => "Text",
                :extraction_form => ef,
                :baseline_characteristic => bc,
                :value => value.to_s + "%"
        }
        @work_order.push(temp)
    end

    def _push_bcdp_checkbox(ef, bc, bcf)
        temp = {:section => "Baseline characteristic",
                :type => "Checkbox",
                :extraction_form => ef,
                :baseline_characteristic => bc,
                :baseline_characteristic_fields => bcf
        }
        @work_order.push(temp)
    end

    def _push_bcdp_checkbox_other(ef, bc, bcf)
        other_columns = ["como1", "como2", "como3", "como4", "como5", "como6", "como7", "como8", "como9", "como10", "como11", "como12", "como13"]
        map = Hash[@data_sd_header.zip 0..@data_sd_header.length]
        other_content = ""
        other_columns.each do |oc|
            more = @row[map[oc]].to_s
            other_content << more unless more.blank?
        end
        temp = {:section => "Baseline characteristic",
                :type => "Checkbox_other",
                :extraction_form => ef,
                :baseline_characteristic => bc,
                :baseline_characteristic_fields => bcf,
                :value => other_content
        }
        @work_order.push(temp)
    end

    def crawl_outcome_detail_answer_columns(ef)
        outcome_details = self.outcome_details(ef)
        outcome_details.each do |od|
            case od.field_type
            when "checkbox"
                outcome_detail_fields = self.outcome_detail_fields(od)
                outcome_detail_fields.each do |odf|
                    column_nr = lookup(odf.option_text)
                    if column_nr.blank?
                        self._log_error(od, odf)
                    elsif @row[column_nr] == 1
                        if odf.option_text.downcase.include? "other"
                            self._push_oddp_checkbox_other(ef, od, odf)
                        else
                            self._push_oddp_checkbox(ef, od, odf)
                        end
                    elsif @row[column_nr] == 0
                        pass
                        #puts "Nothing to do here #{odf.option_text}"
                    else
                        self._log_error(od, odf)
                    end
                end
            when "matrix_radio"
                outcome_detail_fields = OutcomeDetailField.find(:all, :conditions => {:outcome_detail_id => od.id, :column_number => 0})
                outcome_detail_fields.each do |odf|
                    column_nr = lookup(odf.option_text)
                    value = @row[column_nr]
                    self._push_oddp_matrix_radio(ef, od, odf, value)
                end
            when "radio"
                value = @row[157]
                self._push_oddp_radio(ef, od, value)
            end
        end
    end

    def _get_arm_detail_field_columns(ad)
        ArmDetailField.find(:all, :conditions => {:row_number => 0, :arm_detail_id => ad.id})
    end

    def crawl_design_detail_answer_columns(ef)
        design_details = self.design_details(ef)
        design_details.each do |dd|
            case dd.field_type
            when "checkbox"
                design_detail_fields = self.design_detail_fields(dd)
                design_detail_fields.each do |ddf|
                    column_nr = lookup(ddf.option_text)
                    # Check that we actually found a match in the study data row header
                    if column_nr.blank?
                        # If no match was made then we record the error so we can report it later
                        self._log_error(dd, ddf)
                    elsif @row[column_nr] == 1
                        # Push design detail data point onto work_order
                        if ddf.option_text.downcase.include?("other")
                            # Anything with other needs to be handled separately
                            self._push_dddp_checkbox_other(ef, dd, ddf)
                        else
                            self._push_dddp_checkbox(ef, dd, ddf)
                        end
                    elsif @row[column_nr] == 0
                        pass
                        #puts "Nothing to do here #{ddf.option_text}"
                    else
                        self._log_error(dd, ddf)
                    end
                end
            when "matrix_radio"
                design_detail_fields = self.design_detail_fields(dd)
                design_detail_fields.each do |ddf|
                    if ddf.column_number == 0
                        column_nr = lookup(ddf.option_text)
                        if column_nr.blank?
                            self._log_error(dd, ddf)
                        elsif [1, 2, 9].include? @row[column_nr]
                            self._push_dddp_matrix_radio(ef, dd, ddf, @row[column_nr])
                        else
                            self._log_error(dd, ddf)
                        end
                    end
                end
            when "radio"
                column_nr = lookup(dd.question)
                if column_nr.blank?
                    ddf = nil
                    self._log_error(dd, ddf)
                elsif [1, 2].include? @row[column_nr]
                    self._push_dddp_radio(ef, dd, @row[column_nr])
                else
                    self._log_error(dd, ddf)
                end
            when "text"
                column_nr = lookup(dd.question)
                if column_nr.blank?
                    ddf = nil
                    self._log_error(dd, ddf)
                else
                    self._push_dddp_text(ef, dd, @row[column_nr])
                end
            else
                self._log_error(dd, ddf)
            end
        end
    end

    def _push_dddp_text(ef, dd, value)
        # Collect all information required to make an entry in the design detail data field table
        # and add to the work_order array.
        temp = {:section => "Design Detail",
                :type => "Text",
                :extraction_form => ef,
                :design_detail => dd,
                :value => value
        }
        @work_order.push(temp)
    end

    def _push_dddp_radio(ef, dd, value)
        # Collect all information required to make an entry in the design detail data field table
        # and add to the work_order array.
        #convert = {1 => "Yes", 2 => "No", 9 => "Don't know"}
        temp = {:section => "Design Detail", :type => "Radio", :extraction_form => ef, :design_detail => dd, :value => self._convert_yes_no_dontknow(value)}
        @work_order.push(temp)
    end

    def _push_dddp_matrix_radio(ef, dd, ddf, value)
        # Collect all information required to make an entry in the design detail data field table
        # and add to the work_order array.
        #convert = {1 => "Yes", 2 => "No", 9 => "Don't know"}
        temp = {:section => "Design Detail",
                :type => "Matrix_radio",
                :extraction_form => ef,
                :design_detail => dd,
                :design_detail_field => ddf,
                :value => self._convert_yes_no_dontknow(value)}
        @work_order.push(temp)
    end

    def _push_addp_matrix_select(ef, ad, adf, adfc, value)
        convert = {1 => "Hour",
                   2 => "Day",
                   3 => "Week",
                   4 => "Biweekly",
                   5 => "Month",
                   6 => "Year",
                   7 => "Not described",
                   8 => "Not applicable",
                   9 => "Not reported",
                   10 => "Min",
                   11 => "Weekly",
                   12 => "Monthly",
        }
        if adfc.option_text.downcase.include? "units"
            temp = {:section => "Arm Detail",
                    :type => "Matrix_select",
                    :extraction_form => ef,
                    :arm_detail => ad,
                    :arm_detail_field => adf,
                    :value => convert[value],
                    :arm_detail_column_nr => adfc.id,
                    :row_field_id => adf.id
            }
        else
            temp = {:section => "Arm Detail",
                    :type => "Matrix_select",
                    :extraction_form => ef,
                    :arm_detail => ad,
                    :arm_detail_field => adf,
                    :value => value,
                    :arm_detail_column_nr => adfc.id,
                    :row_field_id => adf.id
            }
        end
        @work_order.push(temp)
    end

    def _push_oddp_radio(ef, od, value)
        #convert = {1 => "Yes",
        #           2 => "No",
        #           9 => "Don't know"
        #}

        temp = {:section => "Outcome Detail",
                :type => "Radio",
                :extraction_form => ef,
                :outcome_detail => od,
                :value => self._convert_yes_no_dontknow(value)}
        @work_order.push(temp)
    end

    def _push_oddp_matrix_radio(ef, od, odf, value)
        #convert = {1 => "Yes",
        #           2 => "No",
        #           9 => "Don't know"
        #}

        temp = {:section => "Outcome Detail",
                :type => "Matrix_radio",
                :extraction_form => ef,
                :outcome_detail => od,
                :outcome_detail_field => odf,
                :row_field_id => odf.id,
                :value => self._convert_yes_no_dontknow(value)}
        @work_order.push(temp)
    end

    def _push_dddp_checkbox(ef, dd, ddf)
        # Collect all information required to make an entry in the design detail data field table
        # and add to the work_order array.
        temp = {:section => "Design Detail", :type => "Checkbox", :extraction_form => ef, :design_detail => dd, :design_detail_field => ddf}
        @work_order.push(temp)
    end

    def _push_oddp_checkbox(ef, od, odf)
        temp = {:section => "Outcome Detail", :type => "Checkbox", :extraction_form => ef, :outcome_detail => od, :outcome_detail_field => odf}
        @work_order.push(temp)
    end

    def _push_oddp_checkbox_other(ef, od, odf)
        temp = {:section => "Outcome Detail", :type => "Checkbox_other", :extraction_form => ef, :outcome_detail => od, :outcome_detail_field => odf, :subquestion_value => self.lookup_od_other(odf.option_text)}
        @work_order.push(temp)
    end

    def _push_dddp_checkbox_other(ef, dd, ddf)
        # Collect all information required to make an entry in the design detail data field table
        # and add to the work_order array.
        temp = {:section => "Design Detail", :type => "Checkbox_other", :extraction_form => ef, :design_detail => dd, :design_detail_field => ddf, :subquestion_value => self.lookup_other(ddf.option_text)}
        @work_order.push(temp)
    end

    def print_errors()
        puts @error_stack
    end

    def print_work_order()
        @work_order.each do |order|
            puts ""
            puts order.inspect
            puts ""
        end
        puts @work_order.length
    end

    def lookup(option_text)
        stage1 = {"Multi-center"=>"multi",
                  "Single setting"=>"single",
                  "Community practice"=>"community",
                  "Long-term care facilities"=>"longterm",
                  "VA Healthcare System"=>"va",
                  "Other (study setting)"=>"setting_oth",
                  "Setting not reported"=>"setting_nr",
                  "Government"=>"government",
                  "Hospital"=>"hospital",
                  "Industry"=>"industry",
                  "Private (non-industry)"=>"private",
                  "Other (funding source)"=>"funding_oth",
                  "Unclear"=>"funding_uncl",
                  "Funding not reported"=>"funding_nr",
                  "US"=>"us",
                  "Canada"=>"canada",
                  "UK"=>"uk",
                  "Western Europe"=>"europe",
                  "Eastern Europe"=>"eastern_europe",
                  "Australia/New Zealand"=>"australia_nz",
                  "Is everyone followed up at the same time?" => "Followup",
                  "If no, is the follow-up time reported as a mean" => "FollowupMean",
                  "Asia"=>"asia",
                  "Middle East"=>"middle_east",
                  "Latin America"=>"latin_america",
                  "Other Country"=>"other_country",
                  "Country not reported"=>"country_nr",
                  "Was the method of randomization adequate" => "randapp",
                  "Was the treatment allocation conceled?" => "conceal",
                  "Is the study design trial with crossover?" => "cross",
                  "Did the article include a statement on the role of the funder?" => "funder_role",
                  "What were the study's inclusion criteria?" => "inclusion_text",
                  "What were the study's exclusion criteria?" => "exclusion_text",
                  "Medical record" => "record",
                  "Other (method of assessment)" => "ae_method_oth",
                  "Race/Ethnicity" => "strat_race",
                  "Other (analysis reported)" => "strat_other",
                  "Monitored" => "monitor",
                  "Elicited by investigator" => "investigator",
                  "Reported spontaneously by patient" => "patient",
                  "Adverse event not reported" => "ae_method_nr",
                  "Not applicable" => "ae_method_na",
                  "Age" => "strat_age",
                  "Gender" => "strat_gender",
                  "None of the above" => "strat_noa",
                  "Caucasian" => "white",
                  "African Ancestry" => "black",
                  "Hispanic" => "hispanic",
                  "Asian/Pacific Islander" => "asian",
                  "Native American" => "native",
                  "Eskimo/Inuit" => "eskimo",
                  "Mixed" => "mixed",
                  "Other-Not otherwise specified" => "race_oth_nos",
                  "Race not reported" => "race_nr",
                  "Anxiety" => "co_anxiety",
                  "Dementia/severe geriatric agitation" => "co_dementia",
                  "Depression" => "co_depression",
                  "Insomnia" => "co_insomnia",
                  "Obsessive-compulsive disorder" => "co_ocd",
                  "Personality disorders (DSM IV)" => "co_per_disorder",
                  "PTSD" => "co_ptsd",
                  "Substance abuse" => "co_sub_abuse",
                  "Eating disorder (incl. children 17 &amp; under)" => "co_eat_disorder",
                  "ADHD (incl. children 17 &amp; under)" => "co_adhd",
                  "Tourette's (incl. children 17 &amp; under)" => "co_tourettes",
                  "What was the perfcent of male participants?" => "male",
                  "Mean Age" => "mean_age",
                  "Median Age" => "median_age",
                  "Age Range (upper limit)" => "age_range1",
                  "Age Range (lower limit)" => "age_range2",
                  "Screened" => "nscreen",
                  "Eligible" => "neligible",
                  "Withdrawn" => "nwithdraw",
                  "Loss to follow-up" => "nloss",
                  "[Drop-out rate questions:] Was the drop-out rate described and the reason given? [Yes,No,Don't know]" => "dropouts2",
                  "[Drop-out rate questions:] Was the drop-out rate acceptable? [Yes,No,Don't know]" => "dropoutacc",
                  "[Other sources of potential bias] Were co-interventions avoided or similar? [Yes,No,Don't know]" => "bias_coints",
                  "[Other sources of potential bias] Was the compliance acceptable in all groups? [Yes,No,Don't know]" => "bias_compliance",
                  "[Other sources of potential bias] Was the outcome assessment timing similar in all groups? [Yes,No,Don't know]" => "bias_timing",
                  "Was the study described as randomized? [Yes,No]" => "random",
                  "Were groups similar at baseline regarding the most important prognostic indicators? [Yes,No,Don't know]" => "baseline1",
                  "Is the study described as: [Double blind,Single blind, patient,Single blind, outcome assessment,Single blind, not described,Open,Blinding not described,Not applicable]" => "blind",
                  "If reported, was the method of double blinding appropriate? [Yes,No,Double blinding method not described,Not applicable]" => "blindapp",
                  "Was the outcome assessor blinded? [Yes,No,Don't know]" => "mask_assessor",
                  "Was the care provider blinded? [Yes,No,Don't know]" => "mask_provider",
                  "Were patients blinded? [Yes,No,Don't know]" => "mask_patient",
                  "Were all randomized participants analyzed in the group to which they were originally assigned? [Yes,No,Don't know]" => "original",
        }
        # Build lookup table for easier column access
        stage2 = Hash[@data_sd_header.zip 0..@data_sd_header.length]
        stage2[stage1[option_text]]
    end

    def lookup_other(option_text)
        stage1 = {"Other (study setting)" => ["setting1", "setting2", "setting3", "setting4"],
                  "Other (funding source)" => ["funding_oth1", "funding_oth2", "funding_oth3", "funding_oth4"],
                  "Other Country" => ["other_country_sp"],
        }

        stage2 = Hash[@data_sd_header.zip 0..@data_sd_header.length]

        # Prep empty string. This will hold the content of the 'other' fields
        other_content = ""

        other_fields = stage1[option_text]
        other_fields.each do |other_field|
            col_nr = stage2[other_field]
            more = @row[col_nr]
            other_content << more unless more.blank?
        end
        return other_content
    end

    def lookup_od_other(option_text)
        stage1 = {"Other (method of assessment)" => ["ae_method1", "ae_method2", "ae_method3", "ae_method4"],
                  "Other (analysis reported)" => ["strat_othersp"],
        }

        stage2 = Hash[@data_sd_header.zip 0..@data_sd_header.length]

        # Prep empty string. This will hold the content of the 'other' fields
        other_content = ""

        other_fields = stage1[option_text]
        other_fields.each do |other_field|
            col_nr = stage2[other_field]
            more = @row[col_nr]
            other_content << more unless more.blank?
        end
        return other_content
    end

    def lookup_arm_detail(ad, adf, option_text)
        stage2 = Hash[@data_sd_header.zip 0..@data_sd_header.length]
        if ad.question.downcase.include? "run-in period table"
            convert = {"Length" => "r_length",
                       "Units" => "r_unit",
                       "Placebo/Medication" => "r_int",
                       "How used for randomization?" => "r_random",
            }
        elsif ad.question.downcase.include? "wash-out period table"
            convert = {"Length" => "w_length" + adf.row_number.to_s,
                       "Units" => "w_unit" + adf.row_number.to_s,
                       "Placebo/Medication" => "w_int" + adf.row_number.to_s,
                       "How used for randomization?" => "w_random" + adf.row_number.to_s,
            }
        #elsif ad.question.downcase.include? "arm details"
        #    self._handle_arm_details(ad, adf)
        #    return
        else
            puts ad.question
            puts "+++++++++++++++++++++++++++++++++++++++++++   CONVERSION FAILED"
        end
        stage2[convert[option_text]]
    end

    #def _handle_arm_details(ad, adf)
    #    puts "=+++++++++++++++++++++++++++="
    #    puts "=+++++++++++++++++++++++++++="
    #    puts " NEED TO HANDLE ARM DETAIL NOW "
    #    puts "=+++++++++++++++++++++++++++="
    #    puts "=+++++++++++++++++++++++++++="
    #end

    #def _handle_outcome_details(od, odf)
    #    puts "=+++++++++++++++++++++++++++="
    #    puts "=+++++++++++++++++++++++++++="
    #    puts " NEED TO HANDLE ARM DETAIL NOW "
    #    puts "=+++++++++++++++++++++++++++="
    #    puts "=+++++++++++++++++++++++++++="
    #end

    def _log_error(dd, ddf_item)

        type = dd.field_type
        dd_id = dd.id
        ddf_item_id = ddf_item.id
        ddf_item_option_text = ddf_item.option_text

        error = %Q|
        Type: #{type}
        Design Detail ID: #{dd_id}
        Design Detail Field ID: #{ddf_item_id}
        Option Text: #{ddf_item_option_text}
        Could not look up column number.|

        @error_stack.push(error)
    end

    def errors?
        @error_stack.length != 0
    end

    def write_to_db(wo, creator_id, project_id, study_id)
        case wo[:section]
        when "Design Detail"
            case wo[:type]
            when "Checkbox"
                DesignDetailDataPoint.create(
                    :design_detail_field_id => wo[:design_detail].id,
                    :value => wo[:design_detail_field].option_text,
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Checkbox_other"
                DesignDetailDataPoint.create(
                    :design_detail_field_id => wo[:design_detail].id,
                    :value => wo[:subquestion_value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Matrix_radio"
                #puts "++++++++++++++++++++++++++++"
                #puts wo[:value]
                #puts "++++++++++++++++++++++++++++"
                DesignDetailDataPoint.create(
                    :design_detail_field_id => wo[:design_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => wo[:design_detail_field].id,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Radio"
                DesignDetailDataPoint.create(
                    :design_detail_field_id => wo[:design_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Text"
                DesignDetailDataPoint.create(
                    :design_detail_field_id => wo[:design_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            end
        when "Arm Detail"
            case wo[:type]
            when "Matrix_select"
                arms = Arm.find(:first, :conditions => {:study_id => study_id,
                                                        :display_number => 10
                })
                ArmDetailDataPoint.create(
                    :arm_detail_field_id => wo[:arm_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :arm_id => arms.id,
                    :row_field_id => wo[:row_field_id],
                    :column_field_id => wo[:arm_detail_column_nr]
                )
            end
        when "Arm Detail Arm"
            arms = Arm.find(:first, :conditions => {:study_id => study_id,
                                                    :display_number => wo[:j]
            })
            ArmDetailDataPoint.create(
                :arm_detail_field_id => wo[:arm_detail].id,
                :value => wo[:value],
                :study_id => study_id,
                :extraction_form_id => wo[:extraction_form].id,
                :arm_id => arms.id,
                :row_field_id => wo[:row_field_id],
                :column_field_id => wo[:column_field_id],
                :outcome_id => 0
            )
        when "Outcome Detail"
            case wo[:type]
            when "Checkbox"
                OutcomeDetailDataPoint.create(
                    :outcome_detail_field_id => wo[:outcome_detail].id,
                    :value => wo[:outcome_detail_field].option_text,
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Matrix_radio"
                OutcomeDetailDataPoint.create(
                    :outcome_detail_field_id => wo[:outcome_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => wo[:outcome_detail_field].id,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            when "Radio"
                OutcomeDetailDataPoint.create(
                    :outcome_detail_field_id => wo[:outcome_detail].id,
                    :value => wo[:value],
                    :study_id => study_id,
                    :extraction_form_id => wo[:extraction_form].id,
                    :subquestion_value => wo[:subquestion_value],
                    :row_field_id => 0,
                    :column_field_id => 0,
                    :arm_id => 0,
                    :outcome_id =>0
                )
            end
        when "Baseline characteristic"
            case wo[:type]
            when "Checkbox"
                pass
            when "Checkbox_other"
                pass
            when "Matrix_select"
                pass
            when "Text"
                pass
            end
        when "Quality Dimension"
            QualityDimensionDataPoint.create(
                :quality_dimension_field_id => wo[:quality_dimension_field].id,
                :value => wo[:value],
                :study_id => study_id,
                :extraction_form_id => wo[:quality_dimension_field].extraction_form_id
            )
        end
    end

    def pass; end

    def work_order()
        @work_order
    end

    def clear_work_order()
        @work_order =[]
    end

    def print_current_case_id()
        puts @row[0]
        return @row[0]
    end

    def print_current_case_author()
        puts @row[3]
        return @row[3]
    end

    def _return_value_by_column_nr(column_nr)
        return @row[column_nr]
    end
end






crawler = Crawler.new(project_id, ef_filename, sd_filename)
crawler.clear_work_order()
crawler.extraction_forms.each do |ef|
    #puts "Extraction form ID: " + green(ef.id)
    #puts "Extraction form title: " + green(ef.title)
    #puts "Design details for this extraction form: "

    ef_section_options = EfSectionOption.create(
        :extraction_form_id => ef.id,
        :section => "arm_detail",
        :by_arm => 1,
        :by_outcome => 1
    )

    # Iterate through the studies
    #(1..10).each do |counter|
    (1..1).each do |counter|
        crawler.crawl_design_detail_answer_columns(ef)
        crawler.crawl_arm_detail_answer_columns(ef)
        crawler.crawl_outcome_detail_answer_columns(ef)
        crawler.crawl_baseline_characteristic_answer_columns(ef)
        crawler.crawl_quality_dimension_answer_columns(ef)
        #crawler.print_work_order()

        if crawler.errors?
            abort("ERRORS found..")
        else
            puts "NO ERRORS....LET'S ROLL"
            study = Study.create(
                :project_id => project_id,
                :creator_id => creator_id,
                :extraction_form_id => ef.id
            )
            study_id = study.id
            primary_publication = PrimaryPublication.create(
                :study_id => study_id
            )
            internal_publication_info = PrimaryPublicationNumber.create(
                :primary_publication_id => primary_publication.id,
                :number => crawler.print_current_case_id(),
                :number_type => "internal"
            )
            study_key_question = StudyKeyQuestion.create(
                :study_id => study_id,
                :key_question_id => key_question_id,
                :extraction_form_id => ef.id
            )
            study_extraction_form = StudyExtractionForm.create(
                :study_id => study_id,
                :extraction_form_id => ef.id
            )
            arms1 = Arm.create(
                :study_id => study_id,
                :title => "Placebo",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms2 = Arm.create(
                :study_id => study_id,
                :title => "Aripiprazole",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms3 = Arm.create(
                :study_id => study_id,
                :title => "Asenapine",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms4 = Arm.create(
                :study_id => study_id,
                :title => "Iloperidone",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms5 = Arm.create(
                :study_id => study_id,
                :title => "Olanzapine",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms6 = Arm.create(
                :study_id => study_id,
                :title => "Quetiapine",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms7 = Arm.create(
                :study_id => study_id,
                :title => "Paliperidone",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms8 = Arm.create(
                :study_id => study_id,
                :title => "Risperidone",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms9 = Arm.create(
                :study_id => study_id,
                :title => "Ziprasidone",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            arms10 = Arm.create(
                :study_id => study_id,
                :title => "Other",
                :display_number => Arm.find_all_by_study_id(study_id).length + 1,
                :extraction_form_id => ef.id,
                :is_intention_to_treat => 1
            )
            (1..20).each do |outcome_cnt|
                header_outcome = "outcome#{outcome_cnt}"
                row_data = crawler._get_current_study_data_row()
                column_id = crawler._get_column_id(header_outcome)
                value = crawler._get_cell_value(column_id)
                unless value.blank?
                    puts "header name: #{header_outcome}"
                    puts "column_nr: #{column_id}"
                    puts "value: #{value}"
                    outcome = Outcome.create(
                        :study_id => study_id,
                        :title => value,
                        :is_primary => 1,
                        :units => "",
                        :description => "",
                        :notes => "",
                        :outcome_type => "Time to Event",
                        :extraction_form_id => ef.id
                    )
                    OutcomeSubgroup.create(
                        :outcome_id => outcome.id,
                        :title => "All Participants",
                        :description => "All participants involved in the study (Default)"
                    )
                    header_outcome = "fup#{outcome_cnt}"
                    row_data = crawler._get_current_study_data_row()
                    column_id = crawler._get_column_id(header_outcome)
                    number = crawler._get_cell_value(column_id)

                    header_outcome = "fupunit#{outcome_cnt}"
                    row_data = crawler._get_current_study_data_row()
                    column_id = crawler._get_column_id(header_outcome)
                    unit = crawler._get_cell_value(column_id)
                    unit_conversion = {
                        1 => "Hour",
                        2 => "Day",
                        3 => "Week",
                        4 => "Biweekly",
                        5 => "Month",
                        6 => "Year",
                        9 => "Not Recorded"
                    }
                    OutcomeTimepoint.create(
                        :outcome_id => outcome.id,
                        :number => number,
                        :time_unit => unit_conversion[unit]
                    )
                end
            end
            crawler.work_order.each do |wo|
                crawler.write_to_db(wo, creator_id, project_id, study_id)
            end
        end
        crawler.increment_row_counter()
        crawler.clear_work_order()
        crawler._get_current_study_data_row()
    end
end
puts crawler.print_errors()





