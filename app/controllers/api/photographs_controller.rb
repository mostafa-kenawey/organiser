module Api
  class PhotographsController < ApiApplicationController
    authorize_resource

    api :GET, '/photographers/:id/photographs', "List all photographs in the system"
    api :GET, '/photographs', "List all photographs in the system for current_user photographs"
    description "List all photographs in the system for specifc photographer, Order by 'created_at DESC', It requires organiser user"
    param :secret, String, :desc => "Generated secret for the url /api/photographers/:id/photographs with Organiser user token", :required => true
    param :token, String, :desc => "Organiser user token", :required => true
    example 'Response_success: {"success":true,"photographs":[]}'
    def index
      unless params[:photographer_id].blank?
        photographer = Photographer.find(params[:photographer_id])
      else
        photographer = current_user
      end
      photographs = photographer.photographs.order("created_at desc")
      render :json => { success: true, photographs: photographs.as_json}, :status => 200
    end

    api :POST, '/photographs', "Create new photograph/photographs"
    description "Create a new photographs (support multiple files), It requires photographer user"
    param :secret, String, :desc => "Generated secret for the url /api/photographs with photographer user token", :required => true
    param :token, String, :desc => "Photographer user token", :required => true
    param "photograph['images'][]", Array, :desc => "Array of photograph images", :required => true
    param "photograph['attendee_access_code']", String, :desc => "photograph attendee access_code", :required => true
    example 'Response_success: {"success":true,"photographs":[]]}'
    example 'Response_failure: {"success":false,"errors": {"email": ["cant be blank"]}}'
    def create
      photographs = []
      attendee = Attendee.where(access_code: photograph_params["attendee_access_code"]).first if !photograph_params["attendee_access_code"].blank?

      if attendee
        Photograph.transaction do
          photograph_params["images"].each do |photograph_image|
            photograph = Photograph.new(image: photograph_image, attendee_access_code: attendee.access_code, photographer: current_user)
            photograph.save!
            photographs << photograph
          end
          render :json => { success: true, photographs: photographs.as_json}, :status => 200
        end
      else
        render :json => { success: false, errors: "Invalid Attendee Access Code"}, :status => 200
      end
    end

    #######
    private
    #######

    def photograph_params
      params.require(:photograph).permit(:attendee_access_code, images: [])
    end
  end
end
