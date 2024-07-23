require 'pstore'
require_relative '../questionnaire'

RSpec.describe Questionnaire do
  let(:store_name) { "tendable_test.pstore" }
  let(:store) { PStore.new(store_name) }

  before do
    stub_const("Questionnaire::STORE_NAME", store_name)
    File.delete(store_name) if File.exist?(store_name)
  end

  after do
    File.delete(store_name) if File.exist?(store_name)
  end

  describe '#collect_answers' do
    it 'collects valid answers' do
      input = StringIO.new("yes\nno\ny\nn\nyes\n")
      questionnaire = Questionnaire.new(input.method(:gets))
      answers = questionnaire.collect_answers
      expect(answers).to eq(%w[yes no y n yes])
    end

    it 'handles invalid inputs and collects valid answers' do
      input = StringIO.new("maybe\nyes\nno\ny\nnah\nn\nsure\nyes\n")
      questionnaire = Questionnaire.new(input.method(:gets))
      answers = questionnaire.collect_answers
      expect(answers).to eq(%w[yes no y n yes])
    end
  end

  describe '#save_answers' do
    it 'saves answers to PStore' do
      questionnaire = Questionnaire.new
      answers = %w[yes no yes no yes]
      questionnaire.save_answers(answers)
      stored_answers = nil
      store.transaction do
        stored_answers = store[:answers]
      end
      expect(stored_answers).to eq([answers])
    end

    it 'appends multiple runs to PStore' do
      questionnaire = Questionnaire.new
      answers1 = %w[yes no yes no yes]
      answers2 = %w[no yes no yes no]
      questionnaire.save_answers(answers1)
      questionnaire.save_answers(answers2)
      stored_answers = nil
      store.transaction do
        stored_answers = store[:answers]
      end
      expect(stored_answers).to eq([answers1, answers2])
    end
  end

  describe '#calculate_rating' do
    it 'calculates the correct rating for given answers' do
      questionnaire = Questionnaire.new
      answers = %w[yes no y n yes]
      rating = questionnaire.calculate_rating(answers)
      expect(rating).to eq(60.0)
    end

    it 'calculates a 100% rating for all yes answers' do
      questionnaire = Questionnaire.new
      answers = %w[yes yes yes yes yes]
      rating = questionnaire.calculate_rating(answers)
      expect(rating).to eq(100.0)
    end

    it 'calculates a 0% rating for all no answers' do
      questionnaire = Questionnaire.new
      answers = %w[no no no no no]
      rating = questionnaire.calculate_rating(answers)
      expect(rating).to eq(0.0)
    end
  end

  describe '#calculate_overall_rating' do
    it 'calculates the correct overall rating for all runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes no y n yes])
      questionnaire.save_answers(%w[yes yes yes yes no])
      overall_rating = questionnaire.calculate_overall_rating
      expect(overall_rating).to eq(70.0)
    end

    it 'calculates a 100% overall rating for all yes answers in multiple runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes yes yes yes yes])
      questionnaire.save_answers(%w[yes yes yes yes yes])
      overall_rating = questionnaire.calculate_overall_rating
      expect(overall_rating).to eq(100.0)
    end

    it 'calculates a 0% overall rating for all no answers in multiple runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[no no no no no])
      questionnaire.save_answers(%w[no no no no no])
      overall_rating = questionnaire.calculate_overall_rating
      expect(overall_rating).to eq(0.0)
    end

    it 'calculates the correct overall rating for mixed runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes no y n yes])
      questionnaire.save_answers(%w[no yes no yes no])
      questionnaire.save_answers(%w[yes yes no no no])
      overall_rating = questionnaire.calculate_overall_rating
      expect(overall_rating).to eq(40.0)
    end
  end

  describe '#do_report' do
    it 'prints the correct overall rating' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes no y n yes])
      questionnaire.save_answers(%w[yes yes yes yes no])
      expect { questionnaire.do_report }.to output(/Overall rating for all runs: 70.0%/).to_stdout
    end

    it 'handles no runs gracefully' do
      questionnaire = Questionnaire.new
      expect { questionnaire.do_report }.to output(/Overall rating for all runs: 0.0%/).to_stdout
    end

    it 'prints 100% overall rating for all yes answers in multiple runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes yes yes yes yes])
      questionnaire.save_answers(%w[yes yes yes yes yes])
      expect { questionnaire.do_report }.to output(/Overall rating for all runs: 100.0%/).to_stdout
    end

    it 'prints 0% overall rating for all no answers in multiple runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[no no no no no])
      questionnaire.save_answers(%w[no no no no no])
      expect { questionnaire.do_report }.to output(/Overall rating for all runs: 0.0%/).to_stdout
    end

    it 'prints the correct overall rating for mixed runs' do
      questionnaire = Questionnaire.new
      questionnaire.save_answers(%w[yes no y n yes])
      questionnaire.save_answers(%w[no yes no yes no])
      questionnaire.save_answers(%w[yes yes no no no])
      expect { questionnaire.do_report }.to output(/Overall rating for all runs: 40.0%/).to_stdout
    end
  end
end
