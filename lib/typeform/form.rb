require 'typeform'
require 'json'

module Typeform

  class Form
    attr_reader :form_id

    def initialize(form_id)
      @form_id = form_id
    end

    def all_entries
      response = get
      Hashie::Mash.new(response)
    end

    def complete_entries(params = {})
      #response = get(params.merge(completed: true))
      #Hashie::Mash.new(response)
      response = get(params.merge(completed: true))
      response_hashie = Hashie::Mash.new(response)
      id_to_question_mapper = get_id_to_question_mapper(response_hashie.questions)
      Struct.new("AllForms", :answers, :questions_options_size)
      Struct::AllForms.new(get_forms_answers(response_hashie.responses, id_to_question_mapper),
                           get_questions_options_size(response_hashie.questions))
    end

    def incomplete_entries(params = {})
      response = get(params.merge(completed: false))
      Hashie::Mash.new(response)
    end

    private
      def get(params = nil)
        params ||= {}
        params[:key] = Typeform.api_key
        Typeform.get uri, :query => params
      end

      def uri
        "/form/#{form_id}"
      end

      def get_question_string(questions, question, group_separator = '|')
        if question.key?('group')
          recursive_question = questions.find {|q| q.id == question.group}
          get_question_string(questions, recursive_question) + group_separator + question.question
        else
          question.question
        end
      end

      def get_id_to_question_mapper(questions)
        Hash[questions.collect { |q| [q.id, get_question_string(questions, q)] }]
      end

      def get_forms_answers(responses, id_to_question_mapper)
        forms_answers = []
        responses.each do |response|
          form_answers = Hash.new { |hash, key| hash[key] = Array.new }
          response.answers.each do |id, value|
            form_answers[id_to_question_mapper[id]] << value unless value.nil? || value.empty?
          end
          forms_answers << form_answers
        end
        forms_answers
      end

      def get_questions_options_size(questions)
        questions.each_with_object(Hash.new(0)) { |key, hash| hash[get_question_string(questions, key)] += 1 }
      end
  end

end
