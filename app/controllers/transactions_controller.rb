class TransactionsController < ApplicationController
    before_action :check_login
    def show
        id = params[:id]
        @transaction = Transaction.find(id)
        @converted_amount = convert_amount
    end

    def check_login
        if session[:user_email] == nil
            flash[:notice] = "Invalid session, please login."
            redirect_to welcome_path
        end
    end

    def transform
        money_map = {}
        @total_dues = 0
        @transactions.each do |transaction|
            payer = transaction['payer_email']
            payee = transaction['payee_email']
            is_payer = payer == session[:user_email]
            if is_payer
                @total_dues -= transaction['amount']
                if not money_map.key?(payee)
                    money_map[payee] = transaction['amount']
                else 
                    money_map[payee] += transaction['amount']
                end
            else 
                @total_dues += transaction['amount']
                if not money_map.key?(payee)
                    money_map[payee] = - transaction['amount']
                else 
                    money_map[payee] += - transaction['amount']
                end
            end
        end
        persons = []
        money_map.each do |key, value|
            pmap = {}
            pmap['email'] = key
            pmap['amount_due'] = value
            persons.push(pmap)
        end
        return persons
    end

    def index
        @user_email = session[:user_email]
        @transactions = Transaction.all_transactions_for_user(session[:user_email])
        @persons = transform
    end

    def list
        @user_email = session[:user_email]
        @transactions = Transaction.all_transactions_for_user(session[:user_email])
    end

    def destroy
        @transaction = Transaction.find(params[:id])
        @transaction.destroy
        flash[:notice] = "Transaction '#{@transaction.id}' deleted."
        redirect_to transactions_path
    end

    def new
        @users = Transaction.all_user_mails
    end

    def edit
        @users = Transaction.all_user_mails
        @transaction = Transaction.find params[:id]
    end

    def create
        @transaction = Transaction.create!(transaction_params)
        flash[:notice] = "Transaction was successfully created."
        redirect_to transactions_path
    end

    def update
        @transaction = Transaction.find params[:id]
        @transaction.update_attributes!(transaction_params)
        flash[:notice] = "#{@transaction.id} was successfully updated."
        redirect_to transaction_path(@transaction)
    end

    def convert_amount
        return @transaction.amount.to_s + " (" + @transaction.currency + ")"
    end

    def logout
        session[:user_email] = nil
        flash[:notice] = "User successfully logged out."
        redirect_to welcome_path
    end

    private
    # Making "internal" methods private is not required, but is a common practice.
    # This helps make clear which methods respond to requests, and which ones do not.
    def transaction_params
        params.require(:transaction).permit(:payer_email, :payee_email, :description, :currency, :amount, :percentage, :timestamp)
    end
end

