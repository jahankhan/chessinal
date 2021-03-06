require_relative '../pieces/piece'
require_relative 'display'
require_relative 'cursor'
require_relative '../pieces/rook'
require_relative '../pieces/bishop'
require_relative '../pieces/queen'
require_relative '../pieces/king'
require_relative '../pieces/knight'
require_relative '../pieces/null_piece'
require_relative '../pieces/pawn'

class Board
  attr_reader :grid

  def initialize
    @grid = Array.new(8) { Array.new(8) { NullPiece.instance } }
    initial_setup
    @w_kings_pos = [4,7]
    @b_kings_pos = [4,0]
  end

  def initial_setup
    @grid.each_with_index do |row,row_idx|
      return if row_idx > 1 #return after making pawns
      row.each_with_index do |square,col_idx|
        #Rooks, knights, bishops being created
        if row_idx == 0
          if col_idx == 0
            self.create_piece(:R, [col_idx,row_idx], :BLK)
            self.create_piece(:R, [@grid.length-1-col_idx,row_idx], :BLK)
            self.create_piece(:R, [col_idx, @grid.length-1-row_idx], :W)
            self.create_piece(:R, [@grid.length-1-col_idx, @grid.length-1-row_idx], :W)
          elsif col_idx == 1
            self.create_piece(:N, [col_idx,row_idx], :BLK)
            self.create_piece(:N, [@grid.length-1-col_idx,row_idx], :BLK)
            self.create_piece(:N, [col_idx, @grid.length-1-row_idx], :W)
            self.create_piece(:N, [@grid.length-1-col_idx, @grid.length-1-row_idx], :W)
          elsif col_idx==2
            self.create_piece(:B, [col_idx,row_idx], :BLK)
            self.create_piece(:B, [@grid.length-1-col_idx,row_idx], :BLK)
            self.create_piece(:B, [col_idx, @grid.length-1-row_idx], :W)
            self.create_piece(:B, [@grid.length-1-col_idx, @grid.length-1-row_idx], :W)
          elsif col_idx == 3 #Create queen
            self.create_piece(:Q, [col_idx,row_idx], :BLK)
            self.create_piece(:Q, [col_idx, @grid.length-1-row_idx], :W)
          elsif col_idx == 4 #create king
            self.create_piece(:K, [col_idx,row_idx], :BLK)
            self.create_piece(:K, [col_idx, @grid.length-1-row_idx], :W)
          end
        elsif row_idx == 1 #Create pawns
          self.create_piece(:P, [col_idx,row_idx], :BLK)
          self.create_piece(:P, [col_idx, @grid.length-1-row_idx], :W)
        end
      end
    end
  end

  def create_piece(name, pos, color)
    case name
    when :R
      self[pos] = Rook.new(:R, self, pos, color)
    when :B
      self[pos] = Bishop.new(:B, self, pos, color)
    when :Q
      self[pos] = Queen.new(:Q, self, pos, color)
    when :K
      self[pos] = King.new(:K, self, pos, color)
    when :N
      self[pos] = Knight.new(:N, self, pos, color)
    when :P
      self[pos] = Pawn.new(:P, self, pos, color)
    end
  end


  def [](pos)
    x,y=pos
    @grid[x][y]
  end

  def []=(pos,value)
    x,y=pos
    @grid[x][y] = value
  end

  def move_piece(start_pos, end_pos)
    validate!(start_pos,end_pos)
    valid_moves_arr = self[start_pos].valid_moves
    if valid_moves_arr.include?(end_pos)
      self[end_pos] = self[start_pos]
      self[end_pos].pos = end_pos
      self[start_pos] = NullPiece.instance
      if self[end_pos].is_a?(King)
        self[end_pos].color == :W ? @w_kings_pos=end_pos : @b_kings_pos=end_pos
      end
    else
      raise 'Invalid move'
    end
  end

  def validate!(start_pos,end_pos)
    unless valid_pos?(start_pos) && valid_pos?(end_pos)
      begin
        raise ArgumentError.new("Invalid coordinates given")
      rescue ArgumentError => e
        return false
      end
    end
    !piece_exists?(end_pos)
  end

  def valid_pos?(pos)
    return pos[0].between?(0,7) && pos[1].between?(0,7)
  end

  def piece_exists?(pos)
    if self[pos].is_a?(Piece)
      begin
        raise ArgumentError.new("PIECE AT STARTING LOCATION")
      rescue ArgumentError => e
        return true
      end
    end
    false
  end

  def in_check?(color)
    king_pos = get_king_pos(color)
    @grid.each_with_index do |row,row_idx|
      row.each_with_index do |square,col_idx|
        if square.is_a?(Piece) && square.color != color
          if square.get_moves.any?{ |move| move == king_pos }
            return true
          end
        end
      end
    end
    return false
  end

  def checkmate?(color)
    king_pos = get_king_pos(color)
    @grid.each_with_index do |row,row_idx|
      row.each_with_index do |square,col_idx|
        if square.is_a?(Piece) && square.color==color
          return false unless square.valid_moves.empty?
        end
      end
    end
    if in_check?(color) && self[king_pos].valid_moves.empty?
      return true
    end
    false
  end

  def get_king_pos(color)
    color == :BLK ? @b_kings_pos : @w_kings_pos
  end

  def evaluate
    value = 0
    self.grid.each do |row|
      row.each do |square|
        case square.class.to_s
        when 'NullPiece'
          next
        when 'Pawn'
          square.color == :W ? value += 1 : value -= 1
        when 'Bishop', 'Knight'
          square.color == :W ? value += 3 : value -= 3
        when 'Rook'
          square.color == :W ? value += 5 : value -= 5
        when 'Queen'
          square.color == :W ? value += 9 : value -= 9
        when 'King'
          square.color == :W ? value += 100 : value -= 100
        end
      end
    end
    value
  end

  def dup
    duped_board = Board.new
    duped_board.grid.each_with_index do |row,row_idx|
      row.each_with_index do |square,col_idx|
        duped_board[[row_idx,col_idx]] = self[[row_idx,col_idx]].dup(duped_board)
      end
    end
    return duped_board
  end

  def move_piece!(start_pos, end_pos)
    validate!(start_pos,end_pos)
    self[end_pos] = self[start_pos]
    self[end_pos].pos = end_pos
    self[start_pos] = NullPiece.instance
    if self[end_pos].is_a?(King)
      self[end_pos].color == :W ? @w_kings_pos=end_pos : @b_kings_pos=end_pos
    end
  end
end
