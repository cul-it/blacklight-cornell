# frozen_string_literal: true

# Preview email template on development at http://localhost:3000/rails/mailers/record_mailer/record_email
class RecordMailerPreview < ActionMailer::Preview
    def record_email
        RecordMailer.email_record(documents, details, url, params={})
    end

    def documents
        [ SolrDocument.new(
            {
              "id": "1234",
              "title_display": "Test Title",
              "author_display": "Test Author",
              "format": ["Book", "Video"],
              "language_facet": ["English"], 
              "availability_json": '{"available":true,"availAt":{"Catherwood Library":"AB 123.45", "Kroch Asia Collections":"AB 123.45"}, "unavailAt":{"Uris Library":"AB 123.45"}}'
            }
          ), 
          SolrDocument.new(
            {
              "id": "5678",
              "title_display": "Test Title #2",
              "author_display": "Test Author #2",
              "format": ["Audio"],
              "language_facet": ["English", "French"]
            }
          )
        ]
    end
  
    def details
        { message: "Hello World" }
    end
  
    def url
        {
            host: "localhost",
            port: 9292,
            protocol: "http://"
        }
    end
  end
  