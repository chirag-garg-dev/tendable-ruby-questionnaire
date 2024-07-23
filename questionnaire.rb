require 'pstore'

class Questionnaire
  STORE_NAME = "tendable.pstore"
  QUESTIONS = {
    "q1" => "Can you code in Ruby?",
    "q2" => "Can you code in JavaScript?",
    "q3" => "Can you code in Swift?",
    "q4" => "Can you code in Java?",
    "q5" => "Can you code in C#?"
  }.freeze

  def initialize(input_method = method(:gets))
    @store = PStore.new(STORE_NAME)
    @input_method = input_method
  end

  def collect_answers
    QUESTIONS.keys.map do |question_key|
      print "#{QUESTIONS[question_key]} (Yes/No): "
      a = @input_method.call.chomp.strip.downcase
      until %w[yes no y n].include?(a)
        puts "Invalid answer. Please respond with 'Yes', 'No', 'Y', or 'N'."
        print "#{QUESTIONS[question_key]} (Yes/No): "
        a = @input_method.call.chomp.strip.downcase
      end
      a
    end
  end

  def save_answers(answers)
    @store.transaction do
      @store[:answers] ||= []
      @store[:answers] << answers
    end
  end

  def calculate_rating(answers)
    yes_count = answers.count { |answer| %w[yes y].include?(answer) }
    (100.0 * yes_count / QUESTIONS.size).round(2)
  end

  def calculate_overall_rating
    all_answers = []
    @store.transaction do
      all_answers = @store[:answers] || []
    end

    return 0.0 if all_answers.empty?

    total_yes = all_answers.flatten.count { |answer| %w[yes y].include?(answer) }
    total_questions = all_answers.flatten.size
    (100.0 * total_yes / total_questions).round(2)
  end

  def do_prompt
    answers = collect_answers
    save_answers(answers)
    rating = calculate_rating(answers)
    puts "Your rating for this run: #{rating}%"
  end

  def do_report
    overall_rating = calculate_overall_rating
    puts "Overall rating for all runs: #{overall_rating}%"
  end
end

questionnaire = Questionnaire.new
questionnaire.do_prompt
questionnaire.do_report
