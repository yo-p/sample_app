class User < ApplicationRecord
    before_save :downcase_user_name
    has_many :microposts, dependent: :destroy
    has_many :active_relationships, class_name: "Relationship",
                    foreign_key: "follower_id",
                    dependent: :destroy
    has_many :passive_relationships, class_name: "Relationship",
                    foreign_key: "followed_id",
                    dependent: :destroy
    has_many :following, through: :active_relationships, source: :followed
    has_many :followers, through: :passive_relationships, source: :follower
    attr_accessor :remember_token, :activation_token, :reset_token
    before_save :downcase_email
    before_create :create_activation_digest
    validates :name, presence: true, length: {maximum: 50}
    VALID_EMAIL_REGEX =  /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, length: {maximum: 255},
                format: {with: VALID_EMAIL_REGEX},
                uniqueness: {case_sensitive: false}
    has_secure_password
    validates :password, presence: true, length: {minimum: 6},allow_nil: true
    VALID_USER_NAME_REGEX = /\A[a-z0-9_]+\z/i
    validates :user_name, presence: true, length: {in: 5..15},
                            format: {with: VALID_USER_NAME_REGEX},
                            uniqueness: {case_sensitive: false}
    
    has_many :from_messages, class_name: "Message",
                    foreign_key: "from_id", dependent: :destroy
    has_many :to_messages, class_name: "Message",
                    foreign_key: "to_id", dependent: :destroy
    has_many :sent_messages, through: :from_messages, source: :from
    has_many :received_messages, through: :to_messages, source: :to

    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST:
                                    BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end

    def User.new_token
        SecureRandom.urlsafe_base64
    end

    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
    end

    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end

    def forget
        update_attribute(:remember_digest, nil)
    end

    def activate
        update_columns(activated: true, activated_at: Time.zone.now)
        # update_attribute(:activated, true)
        # update_attribute(:activated_at, Time.zone.now)
    end

    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end

    def create_reset_digest
        self.reset_token = User.new_token
        update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
        # update_attribute(:reset_digest, User.digest(reset_token))
        # update_attribute(:reset_sent_at, Time.zone.now)
    end

    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now
    end

    def password_reset_expired?
        reset_sent_at < 2.hours.ago
    end

    # ユーザーのステータスフィードを返す
    def feed
        following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
        Micropost.including_replies(id).where("user_id IN (#{following_ids}) 
                        OR user_id = :user_id", user_id: id)
    end

    # ユーザーをフォローする
    def follow(other_user)
        active_relationships.create(followed_id: other_user.id)
        if other_user.follow_notification
            Relationship.send_follow_email(other_user, self)
        end
    end

    # ユーザーをフォロー解除する
    def unfollow(other_user)
        active_relationships.find_by(followed_id: other_user.id).destroy
        if other_user.follow_notification
            Relationship.send_unfollow_email(other_user, self)
        end
    end

    # 現在のユーザーがフォローしてたらtrueを返す
    def following?(other_user)
        following.include?(other_user)
    end

    # Send message to other user
    def send_message(other_user, room_id, content)
        from_messages.create!(to_id: other_user.id, room_id: room_id, content: content)
    end

    private

    def downcase_email
        self.email = email.downcase
    end

    def create_activation_digest
        self.activation_token = User.new_token
        self.activation_digest = User.digest(activation_token)
    end

    def downcase_user_name
        self.user_name.downcase!
    end
end
