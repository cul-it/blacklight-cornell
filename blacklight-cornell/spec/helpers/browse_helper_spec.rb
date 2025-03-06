require 'rails_helper'

describe BrowseHelper do
  describe '#build_search_link' do
    before do
      assign(:heading_document, HeadingSolrDocument.new(solr_doc_response))
    end

      context 'personal name heading type' do
        let(:solr_doc_response) {
          { 'headingTypeDesc' => 'Personal Name', 'heading' => 'Beethoven, Ludwig van, 1770-1827.' }
        }

        it 'returns catalog search link' do
          expect(helper.build_search_link('Musical Recording', 20)).
            to eq(
              '<a id="facet_link_musical_recording" href="/catalog'\
              '?advanced_query=yes'\
              '&boolean_row%5B1%5D=OR'\
              '&f%5Bformat%5D%5B%5D=Musical+Recording'\
              '&op_row%5B%5D=AND&op_row%5B%5D=AND'\
              '&q_row%5B%5D=Beethoven%2C+Ludwig+van%2C+1770-1827.&q_row%5B%5D=Beethoven%2C+Ludwig+van%2C+1770-1827.'\
              '&search_field=advanced'\
              '&search_field_row%5B%5D=subject_pers_browse&search_field_row%5B%5D=author_pers_browse'\
              '">Musical Recordings (20)</a>'
            )
        end
      end

      context 'geographic name heading type' do
        let(:solr_doc_response) {
          { 'headingTypeDesc' => 'Topical Term', 'heading' => 'House buying > Handbooks, manuals, etc.' }
        }

        it 'returns catalog search link' do
          expect(helper.build_search_link('Manuscript/Archive', 4)).
            to eq(
              '<a id="facet_link_manuscript_archive" href="/catalog'\
              '?advanced_query=yes'\
              '&f%5Bformat%5D%5B%5D=Manuscript%2FArchive'\
              '&op_row%5B%5D=AND'\
              '&q_row%5B%5D=House+buying+%3E+Handbooks%2C+manuals%2C+etc.'\
              '&search_field=advanced'\
              '&search_field_row%5B%5D=subject_topic_browse'\
              '">Manuscripts/Archives (4)</a>'
            )
        end

      context 'subject heading, work heading type' do
        let(:solr_doc_response) {
          { 'headingTypeDesc' => 'Work', 'heading' => 'Shakespeare, William, 1564-1616. | All\'s well that ends well' }
        }

        it 'returns catalog search link' do
          expect(helper.build_search_link('Book', 46)).
            to eq(
              '<a id="facet_link_book" href="/catalog'\
              '?advanced_query=yes'\
              '&boolean_row%5B1%5D=OR'\
              '&f%5Bformat%5D%5B%5D=Book'\
              '&op_row%5B%5D=AND&op_row%5B%5D=AND'\
              '&q_row%5B%5D=Shakespeare%2C+William%2C+1564-1616.+%7C+All%27s+well+that+ends+well&q_row%5B%5D=Shakespeare%2C+William%2C+1564-1616.+%7C+All%27s+well+that+ends+well'\
              '&search_field=advanced'\
              '&search_field_row%5B%5D=subject_work_browse&search_field_row%5B%5D=authortitle_browse'\
              '">Books (46)</a>'
            )
        end
      end

      context 'authortitle heading' do
        let(:solr_doc_response) {
          { 'heading' => 'Shakespeare, William, 1564-1616. | All\'s well that ends well' }
        }

        it 'returns catalog search link' do
          expect(helper.build_search_link('Book', 46)).
            to eq(
              '<a id="facet_link_book" href="/catalog'\
              '?advanced_query=yes'\
              '&boolean_row%5B1%5D=OR'\
              '&f%5Bformat%5D%5B%5D=Book'\
              '&op_row%5B%5D=AND&op_row%5B%5D=AND'\
              '&q_row%5B%5D=Shakespeare%2C+William%2C+1564-1616.+%7C+All%27s+well+that+ends+well&q_row%5B%5D=Shakespeare%2C+William%2C+1564-1616.+%7C+All%27s+well+that+ends+well'\
              '&search_field=advanced'\
              '&search_field_row%5B%5D=subject_work_browse&search_field_row%5B%5D=authortitle_browse'\
              '">Books (46)</a>'
            )
        end
      end
    end
  end

  describe '#pluralize_format' do
    it 'returns pluralized format' do
      expect(helper.pluralize_format('Book')).to eq('Books')
      expect(helper.pluralize_format('Journal/Periodical')).to eq('Journals/Periodicals')
      expect(helper.pluralize_format('Manuscript/Archive')).to eq('Manuscripts/Archives')
      expect(helper.pluralize_format('Map')).to eq('Maps')
      expect(helper.pluralize_format('Musical Score')).to eq('Musical Scores')
      expect(helper.pluralize_format('Non-musical Recording')).to eq('Non-musical Recordings')
      expect(helper.pluralize_format('Video')).to eq('Videos')
      expect(helper.pluralize_format('Computer File')).to eq('Computer Files')
      expect(helper.pluralize_format('Database')).to eq('Databases')
      expect(helper.pluralize_format('Musical Recording')).to eq('Musical Recordings')
      expect(helper.pluralize_format('Thesis')).to eq('Theses')
      expect(helper.pluralize_format('Microform')).to eq('Microforms')
      expect(helper.pluralize_format('Miscellaneous')).to eq('Miscellaneous')
    end
  end
end
