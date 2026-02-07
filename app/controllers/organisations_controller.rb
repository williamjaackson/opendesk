class OrganisationsController < ApplicationController
  def index
    redirect_to root_path if Current.organisation.present?

    @organisations = Current.user.organisations
    @organisations = @organisations.where("name LIKE ?", "%#{params[:query]}%") if params[:query].present?
    @pagy, @organisations = pagy(@organisations)
  end

  def show
    @organisation = Current.user.organisations.find(params[:id])
  end

  def members
    @organisation = Current.user.organisations.find(params[:id])
    @current_membership = @organisation.organisation_users.find_by(user: Current.user)
    @members = @organisation.organisation_users.includes(:user).order(:created_at)
    @pending_invites = @organisation.organisation_invites.pending.order(:created_at)
    @invite = @organisation.organisation_invites.new
  end

  def new
    @organisation = Organisation.new
  end

  def create
    @organisation = Organisation.new(organisation_params)

    if @organisation.save
      @organisation.organisation_users.create!(user: Current.user, role: "admin")
      redirect_to organisations_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @organisation = Current.user.organisations.find(params[:id])
  end

  def update
    @organisation = Current.user.organisations.find(params[:id])

    if @organisation.update(organisation_params)
      redirect_to organisation_path(@organisation)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def leave
    @organisation = Current.user.organisations.find(params[:id])
    membership = @organisation.organisation_users.find_by!(user: Current.user)

    if @organisation.organisation_users.count == 1
      redirect_to organisation_path(@organisation), alert: "You can't leave as the last member."
      return
    end

    if membership.admin? && @organisation.organisation_users.where(role: "admin").count == 1
      redirect_to organisation_path(@organisation), alert: "You can't leave as the only admin. Make someone else an admin first."
      return
    end

    session.delete(:organisation_id) if session[:organisation_id] == @organisation.id
    membership.destroy
    redirect_to organisations_path, notice: "You've left #{@organisation.name}."
  end

  def destroy
    @organisation = Current.user.organisations.find(params[:id])
    @organisation.destroy
    redirect_to organisations_path
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name, :theme_colour)
  end
end
