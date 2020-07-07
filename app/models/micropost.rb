class Micropost < ApplicationRecord

  before_validation :set_in_reply_to

  belongs_to :user
  default_scope -> {order(created_at: :desc)}
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :content, presence: true, length: {maximum: 140}
  validates :in_reply_to, presence: false
  validate :picture_size, :reply_to_user

  def Micropost.including_replies(id)
    where(in_reply_to: [id, 0]).or(Micropost.where(user_id: id))
  end

  def is_i?(s)
    Integer(s) != nil rescue false
  end

  def set_in_reply_to
    if @index = content.index("@")
      reply_id = []
      while is_i?(content[@index + 1])
        @index += 1
        reply_id << content[@index]
      end
      self.in_reply_to = reply_id.join.to_i
    else 
      self.in_reply_to = 0
    end
  end

  def reply_to_user_name_correct?(user)
    user_name = user.name.gsub(" ", "-")
    content[@index + 2, user_name.length] == user_name
  end

  def reply_to_user
    return if self.in_reply_to == 0
    unless user = User.find_by(id: self.in_reply_to)
      errors.add(:base, "User ID you specified doesn't exist.")
    else
      if user_id == self.in_reply_to
        errors.add(:base, "You can't reply to yourself.")
      else
        unless reply_to_user_name_correct?(user)
          errors.add(:base, "User ID doesn't match its name.")
        end
      end
    end
  end

  private

  # アップロードされてた画像のサイズをバリデーションする
  def picture_size
    if picture.size > 5.megabytes
      errors.add(:picture, "should be less than 5MB")
    end
  end
end
