module ApplicationHelper

  #ページごとの完全なタイトルを返します。
  def full_title(page_title = '')     #メッソド定義とオプション引数
    base_title = "Ruby on Rails Tutorial Sample App"  #変数へ代入
    if page_title.empty?                            #論理テスト
      base_title                                   #暗黙の戻り値
    else
      page_title + " | " + base_title                 #文字列の結合
    end
  end

end
