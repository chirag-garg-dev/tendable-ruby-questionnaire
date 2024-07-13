require 'pstore'

STORE_NAME = "tendable.pstore"
store = PStore.new(STORE_NAME)

QUESTIONS = {
  "q1" => "Can you code in Ruby?",
  "q2" => "Can you code in JavaScript?",
  "q3" => "Can you code in Swift?",
  "q4" => "Can you code in Java?",
  "q5" => "Can you code in C#?"
}.freeze

def do_prompt
  answers = QUESTIONS.keys.map do |question_key|
    print "#{QUESTIONS[question_key]} (Yes/No): "
    a = gets.chomp.strip.downcase
    until %w[yes no y n].include?(a)
      puts "Invalid answer. Please respond with 'Yes', 'No', 'Y', or 'N'."
      print "#{QUESTIONS[question_key]} (Yes/No): "
      a = gets.chomp.strip.downcase
    end
    a
  end

  save_answers(answers)
  rating = calculate_rating(answers)
  puts "Your rating for this run: #{rating}%"
end

def save_answers(answers)
  store = PStore.new(STORE_NAME)
  store.transaction do
    store[:answers] ||= []
    store[:answers] << answers
  end
end

def calculate_rating(answers)
  yes_count = answers.count { |answer| %w[yes y].include?(answer) }
  (100.0 * yes_count / QUESTIONS.size).round(2)
end

def calculate_overall_rating
  store = PStore.new(STORE_NAME)
  all_answers = []
  store.transaction do
    all_answers = store[:answers] || []
  end

  total_yes = all_answers.flatten.count { |answer| %w[yes y].include?(answer) }
  total_questions = all_answers.flatten.size
  (100.0 * total_yes / total_questions).round(2)
end

def do_report
  overall_rating = calculate_overall_rating
  puts "Overall rating for all runs: #{overall_rating}%"
end

do_prompt
do_report
