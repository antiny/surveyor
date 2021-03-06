class ResponseQuestion
  attr_reader :response, :question, :answer_wrappers
  delegate :type, :id, :title, to: :question

  def initialize(response, question)
    @response = response
    @question = question
    @answer_wrappers = question.choices.map do |choice|
      Answer.new(question: question, choice: choice)
    end
    prefill
  end

  def prefill
    answer_wrappers.each_with_index do |response_choice, index|
      if a = response.answers_for(question: response_choice.question, choice: response_choice.choice).first
        answer_wrappers[index] = a
      end
    end
  end
end

class ResponseForm < Reform::Form
  property :ip

  def questions
    survey.questions
  end

  def survey_title
    survey.title
  end

  def survey
    model.survey
  end

  def response_questions
    @resposne_questions ||= questions.map do |question|
      ResponseQuestion.new(model, question)
    end
  end

  # TODO: move saving outside validate
  def validate(attrs)
    super
    attrs['questions'].each do |index, hash|
      if id = hash['answers'].delete('id').presence
        answer = Answer.find id
      else
        answer = Answer.new response: model
      end
      answer.update_attributes!(hash['answers'])
    end
  end
end
