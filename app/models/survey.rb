class Survey < ApplicationRecord
  has_many :responses, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :collaborations, dependent: :destroy

  validates :title, presence: true

  def responses_count
    responses.size
  end

  def last_response_at
    responses.order(updated_at: :desc).first.try(:updated_at)
  end

  def create_owner!(user)
    collaborations.create! user: user, role: :owner
  end

  def allow_collaboration?(user, action)
    if role = collaborations.find_by(user: user).try(:role)
      Collaboration::SURVEY_ACTIONS[role.to_sym].include?(action)
    end
  end

  def generate_response
    puts "generate response for #{self.inspect}"
    transaction do
      r = responses.create!
      questions.each do |q|
        puts "--> generate answer for #{q.inspect}"
        case q.type.to_sym
          when :short_answer
            content = %w(harley thuan an anta thinh thanh).sample
            q.choices.each do |c|
              r.answers.create! question: q, choice: c, content: content
            end
          when :multiple_choice
            c = q.choices.sample
            r.answers.create! question: q, choice: c, content: c.content
          # ...
          when :check_boxes
            size = q.choices.size # .length, .count
            num  = rand(size) + 1
            q.choices.shuffle.take(num).each do |c|
              r.answers.create! question: q, choice: c, content: c.content
            end
          else
            raise "Unknown type: #{q.type}"
        end
      end
    end
  end
end
