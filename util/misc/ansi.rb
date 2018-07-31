require_relative './dings'
module AnsiClr

  include Dings
  OP = 27.chr + '[' # ANSI color control opening symbols
  PLAIN = '0'
  RESET = "#{OP}m"
  
  # Styles:
  BOLD = '1'
  DIM = '2'
  ULINE = '4'
  BLINK = '5'
  REVERSE = '7'
  HIDDEN = '8'
  REBOLD = "2#{BOLD}"
  REDIM = "2#{DIM}"
  REULINE = "2#{ULINE}"
  REBLINK = "2#{BLINK}"
  REREVERSE = "2#{REVERSE}"
  REHIDDEN = "2#{HIDDEN}"
  
  # Foregrounds:
  F_DEF = '39'
  F_BLACK = '30'
  F_RED = '31'
  F_GREEN = '32'
  F_BROWN = '33'
  F_YELLOW = F_BROWN
  F_BLUE = '34'
  F_PURPLE = '35'
  F_MAGENTA = F_PURPLE
  F_CYAN = '36'
  F_LGREY = '37'
  F_LGRAY = F_LGREY
  F_DGREY = '90'
  F_DGRAY = F_DGREY

  F_LRED = '91'
  F_LGREEN = '92'
  F_LBROWN = '93'
  F_LYELLOW = F_LBROWN
  F_LBLUE = '94'
  F_LPURPLE = '95'
  F_LMAGENTA = F_LPURPLE
  F_LCYAN = '96'
  F_WHITE = '97'
  CL = 'm'
  
  B_BLACK = '40'
  B_RED = '41'
  B_GREEN = '42'
  B_BROWN = '43'
  B_YELLOW = B_BROWN
  B_BLUE = '44'
  B_PURPLE = '45'
  B_MAGENTA = B_PURPLE
  B_CYAN = '46'
  B_LGREY = '47'
  B_LGRAY = B_LGREY
  B_DGREY = '100'
  B_DGRAY = B_DGREY

  B_PLAIN = '49'
  B_DEFAULT = B_PLAIN

  B_LRED = '101'
  B_LGREEN = '102'
  B_LBROWN = '103'
  B_LYELLOW = B_LBROWN
  B_LBLUE = '104'
  B_LPURPLE = '105'
  B_LMAGENTA = B_LPURPLE
  B_LCYAN = '106'
  B_WHITE = '107'

  STYLES = {
      BOLD => 'BOLD',
      DIM => 'DIM',
      ULINE => 'ULINE',
      BLINK => 'BLINK',
      REVERSE => 'REVERSE',
      HIDDEN => 'HIDDEN',
      REBOLD => 'RE-BOLD',
      REDIM => 'RE-DIM',
      REULINE => 'RE-ULINE',
      REBLINK => 'RE-BLINK',
      REREVERSE => 'RE-REVERSE',
      REHIDDEN => 'RE-HIDDEN'
  }
  
  FORES = {
      F_DEF => 'F_DEF',
      F_BLACK => 'F_BLACK',
      F_RED => 'F_RED',
      F_GREEN => 'F_GREEN',
      F_BROWN => 'F_BROWN',
      F_BLUE => 'F_BLUE',
      F_PURPLE => 'F_PURPLE',
      F_CYAN => 'F_CYAN',
      F_LGREY => 'F_LGREY',
      F_DGREY => 'F_DGREY',
      F_LRED => 'F_LRED',
      F_LGREEN => 'F_LGREEN',
      F_LBROWN => 'F_LBROWN',
      F_LBLUE => 'F_LBLUE',
      F_LPURPLE => 'F_LPURPLE',
      F_LCYAN => 'F_LCYAN',
      F_WHITE => 'F_WHITE',
  }
  
  BACKS = {
      B_BLACK => 'B_BLACK',
      B_RED => 'B_RED',
      B_GREEN => 'B_GREEN',
      B_BROWN => 'B_BROWN',
      B_BLUE => 'B_BLUE',
      B_PURPLE => 'B_PURPLE',
      B_CYAN => 'B_CYAN',
      B_LGREY => 'B_LGREY',
      B_DGREY => 'B_DGREY',

      B_DEFAULT => 'B_DEFAULT',

      B_LRED => 'B_LRED',
      B_LGREEN => 'B_LGREEN',
      B_LBROWN => 'B_LBROWN',
      B_LBLUE => 'B_LBLUE',
      B_LPURPLE => 'B_LPURPLE',
      B_LCYAN => 'B_LCYAN',
      B_WHITE => 'B_WHITE',
  }

  def test
    puts
    out = ''
    BACKS.keys.each { |b|
      FORES.keys.each { |f|
        STYLES.keys.each { |s|
          out << %<#{LLQBIG}#{OP}#{s};#{f};#{b}m#{FORES[f]}/#{BACKS[b]}:#{STYLES[s]}#{RESET}#{RRQBIG}>
          if out.length > 240 # accounting for non-visual symbols
            puts out
            out = ''
          end
        }
      }
      print "\n"
    }
    puts
  end
  module_function :test
end

