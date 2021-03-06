class MealsController < ApplicationController
  before_action :set_meal, only: [:show, :edit, :update, :destroy]

  authorize_resource

  respond_to :html, :json

  DEFAULT_LATITUDE = 51.4980188
  DEFAULT_LONGITUDE = -2.1860654

  def index

    # cache user latitude and longitude
    if current_user && !params[:latitude].blank? && !params[:longitude].blank?
      current_user.current_latitude = params[:latitude].to_f
      current_user.current_longitude = params[:longitude].to_f
      current_user.save
    end

    # set search variables
    @latitude = (params[:latitude] || current_user.try(:current_latitude) || DEFAULT_LATITUDE).to_f
    @longitude = (params[:longitude] || current_user.try(:current_longitude) || DEFAULT_LONGITUDE).to_f
    @distance = 400

    # run search
    if !params[:category].blank? && !params[:category][:category_id].blank? && params[:search]
      @meals = Meal.near([@latitude, @longitude], @distance).available.tonight.where("LOWER(name) like ? AND category_id = ?", "%#{params[:search].downcase}%", params[:category][:category_id].to_i)
    elsif !params[:category].blank? && !params[:category][:category_id].blank?
      @meals = Meal.near([@latitude, @longitude], @distance).available.tonight.where("category_id = ?", params[:category][:category_id].to_i) #.page(params[:page])
    elsif params[:search]
      @meals = Meal.near([@latitude, @longitude], @distance).available.tonight.where("LOWER(name) like ?", "%#{params[:search].downcase}%")
    else
      @meals = Meal.near([@latitude, @longitude], @distance).available.tonight #.page(params[:page])
    end

    if request.env["HTTP_USER_AGENT"] =~ /Mobile|webOS/
      if request.xhr?
        render @meals, layout: false # meals partial (inserted into list)
      else
        render :index # view for mobile (list)
      end
    else
      # desktop
      if request.xhr?
        respond_with(@meals) # meals via serializer (rendered on map)
      else
        render :indexdesktop # view for desktop (map)
      end
    end

  end

  def show
    respond_with(@meal)
  end

  def new
    @meal = Meal.new
    respond_with(@meal)
  end

  def edit
  end

  def create
    @meal = Meal.new(meal_params)
    @meal.user_id = current_user.id
    @meal.latitude = @meal.user.latitude
    @meal.longitude = @meal.user.longitude
    if @meal.save
      flash[:notice] = "Meal created."
      respond_with(@meal)
    else
      render :new
    end
  end

  def update
    if @meal.update(meal_params)
      flash[:notice] = "Meal updated."
      respond_with(@meal)
    else
      render :edit
    end
  end

  def destroy
    @meal.destroy
    flash[:notice] = "Meal deleted."
    respond_with(@meal)
  end

  private
  def set_meal
    @meal = Meal.find(params[:id])
  end

  private
  def meal_params
    params.require(:meal).permit(:category_id, :name, :description, :price, :quantity, :start_at, :end_at)
  end

end
