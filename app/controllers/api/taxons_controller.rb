module Api
  class TaxonsController < Api::BaseController
    respond_to :json

    skip_authorization_check only: [:index, :show, :jstree]

    def index
      if taxonomy
        @taxons = taxonomy.root.children
      else
        if params[:ids]
          @taxons = Spree::Taxon.where(id: params[:ids].split(","))
        else
          @taxons = Spree::Taxon.ransack(params[:q]).result
        end
      end
      render json: @taxons, each_serializer: Api::TaxonSerializer
    end

    def jstree
      @taxon = taxon
      render json: @taxon.children, each_serializer: Api::TaxonJstreeSerializer
    end

    def create
      authorize! :create, Spree::Taxon
      @taxon = Spree::Taxon.new(params[:taxon])
      @taxon.taxonomy_id = params[:taxonomy_id]
      taxonomy = Spree::Taxonomy.find_by_id(params[:taxonomy_id])

      if taxonomy.nil?
        @taxon.errors[:taxonomy_id] = I18n.t(:invalid_taxonomy_id, scope: 'spree.api')
        invalid_resource!(@taxon) && return
      end

      @taxon.parent_id = taxonomy.root.id unless params[:taxon][:parent_id]

      if @taxon.save
        render json: @taxon, serializer: Api::TaxonSerializer, status: :created
      else
        invalid_resource!(@taxon)
      end
    end

    def update
      authorize! :update, Spree::Taxon
      if taxon.update_attributes(params[:taxon])
        render json: taxon, serializer: Api::TaxonSerializer, status: :ok
      else
        invalid_resource!(taxon)
      end
    end

    def destroy
      authorize! :delete, Spree::Taxon
      taxon.destroy
      render json: taxon, serializer: Api::TaxonSerializer, status: :no_content
    end

    private

    def taxonomy
      return if params[:taxonomy_id].blank?
      @taxonomy ||= Spree::Taxonomy.find(params[:taxonomy_id])
    end

    def taxon
      @taxon ||= taxonomy.taxons.find(params[:id])
    end
  end
end
