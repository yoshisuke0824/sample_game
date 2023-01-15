require 'dxopal'
include DXOpal

GROUND_Y = 400
# 使用する画像を宣言
Image.register(:player, 'images/player.png')
Image.register(:apple, 'images/apple.png')
Image.register(:bomb, 'images/bomb.png')
# 使用する効果音を宣言
Sound.register(:get, 'sounds/get.wav')
Sound.register(:explosion, 'sounds/explosion.wav')

# ゲームの状態を記憶するハッシュを追加
GAME_INFO = {
  scene: :title,  # 現在のシーン(起動直後は:title)
  score: 0,
  time: 0,
}

class Player < Sprite
  def initialize
    x = Window.width / 2
    y = GROUND_Y - Image[:player].height
    image = Image[:player]
    super(x, y, image)
    # 当たり判定を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 16]
  end

  # 移動処理(xからself.xになった)
  def update
    if Input.key_down?(K_LEFT) && self.x > 0
      self.x -= 8
    elsif Input.key_down?(K_RIGHT) && self.x < (Window.width - Image[:player].width)
      self.x += 8
    end
  end
end

# アイテムを表すクラスを追加
class Item < Sprite
  # imageを引数にとるようにした
  def initialize(image)
    x = rand(Window.width - image.width)
    y = -100
    super(x, y, image)
    @speed_y = rand(4) + 4 + (GAME_INFO[:time] / (60 * 5)).to_i
  end

  def update
    self.y += @speed_y
    if self.y > Window.height
      self.vanish
    end
  end
end

# 加点アイテムのクラスを追加
class Apple < Item
  def initialize
    super(Image[:apple])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 56]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    Sound[:get].play
    self.vanish
    GAME_INFO[:score] += 10
  end
end

# 妨害アイテムのクラスを追加
class Bomb < Item
  def initialize
    super(Image[:bomb])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 42]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    Sound[:explosion].play
    self.vanish
    # スコアを0にするのをやめて、ゲームオーバー画面に遷移するようにした
    GAME_INFO[:scene] = :game_over
  end
end

# アイテム群を管理するクラスを追加
class Items
  N = 5

  def initialize
    @items = []
  end

  # playerを引数に取るようにした
  def update(player)
    @items.each{|x| x.update(player)}
    # playerとitemsが衝突しているかチェックする。衝突していたらhitメソッドが呼ばれる
    Sprite.check(player, @items)
    Sprite.clean(@items)

    (N - @items.size).times do
      if rand(100) < 40
        @items.push(Apple.new)
      else
        @items.push(Bomb.new)
      end
    end
  end

  def draw
    Sprite.draw(@items)
  end
end

# ゲーム本体を表すクラス
class Game
  def initialize
    reset
  end

  # ゲームの状態をリセットする
  def reset
    @player = Player.new
    @items = Items.new
    GAME_INFO[:score] = 0
    GAME_INFO[:time] = 0
  end

  # ゲームを実行する
  def run
    Window.loop do
      Window.draw_box_fill(0, 0, Window.width, GROUND_Y, [128, 255, 255])
      Window.draw_box_fill(0, GROUND_Y, Window.width, Window.height, [0, 128, 0])
      Window.draw_font(0, 0, "SCORE: #{GAME_INFO[:score]}", Font.default)
      Window.draw_font(0, 20, "TIME: #{(GAME_INFO[:time] / 60).round(1)}", Font.default)

      case GAME_INFO[:scene]
      when :title
        Window.draw_font(Window.width / 2 - 200, Window.height / 2, "スペースキーを押してスタート", Font.default, option={color: [0,0,0]})
        if Input.key_push?(K_SPACE)
          GAME_INFO[:scene] = :playing
        end
      when :playing
        @player.update
        @items.update(@player)
        GAME_INFO[:time] += 1

        @player.draw
        @items.draw
      when :game_over
        @player.draw
        @items.draw
        Window.draw_font(Window.width / 2 - 250, Window.height / 2, "GAME OVER スペースキーを押してスタート", Font.default, option={color: [0,0,0]})
        if Input.key_push?(K_SPACE)
          reset
          GAME_INFO[:scene] = :playing
        end
      end

    end
  end
end

Window.load_resources do
  game = Game.new
  game.run
end