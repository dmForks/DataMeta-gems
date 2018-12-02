require_relative './glyphs'
module DataMetaXtra

# ANSI control sequences.
module AnsiCtl

# https://en.wikipedia.org/wiki/ANSI_escape_code

# Skip ANSI Escape sequences unless this env var is defined and set to 'yes'
  SKIP_ANSI_ESC = ENV['DATAMETA_USE_ANSI_CTL'] != 'yes'
  include Glyphs
  # ANSI escape operation start
  OP = SKIP_ANSI_ESC ? '' : 27.chr + '['
  # ANSI atribute divider. When the ANSI seqs are disabled, this takes care of concatenating those.
  ATRB_DIV = SKIP_ANSI_ESC ? ';' : ''
  # Plain text
  PLAIN = SKIP_ANSI_ESC ? '' : '0'
  # Reset sequence
  RESET = SKIP_ANSI_ESC ? '' : "#{OP}m"
  
  # Styles:
  # Bold
  BOLD = SKIP_ANSI_ESC ? '' : '1'
  # Dimmed
  DIM = SKIP_ANSI_ESC ? '' : '2'
  # Underline
  ULINE = SKIP_ANSI_ESC ? '' : '4'
  # Blinking
  BLINK = SKIP_ANSI_ESC ? '' : '5'
  # Reverse graphics
  REVERSE = SKIP_ANSI_ESC ? '' : '7'
  # Hidden text - to enter passwords
  HIDDEN = SKIP_ANSI_ESC ? '' : '8'
  # Reset Bold
  REBOLD = SKIP_ANSI_ESC ? '' : "2#{BOLD}"
  # Reset Dim
  REDIM = SKIP_ANSI_ESC ? '' : "2#{DIM}"
  # Reset Underline
  REULINE = SKIP_ANSI_ESC ? '' : "2#{ULINE}"
  # Reset Blink
  REBLINK = SKIP_ANSI_ESC ? '' : "2#{BLINK}"
  # Reset reverse graphics
  REREVERSE = SKIP_ANSI_ESC ? '' : "2#{REVERSE}"
  # Reset hidden text
  REHIDDEN = SKIP_ANSI_ESC ? '' : "2#{HIDDEN}"
  
  # Foregrounds:
  # Default foreground
  F_DEF = SKIP_ANSI_ESC ? '' : '39'
  # Black foreground
  F_BLACK = SKIP_ANSI_ESC ? '' : '30'
  #  Red foreground
  F_RED = SKIP_ANSI_ESC ? '' : '31'
  # Green foreground
  F_GREEN = SKIP_ANSI_ESC ? '' : '32'
  # Brown foreground
  F_BROWN = SKIP_ANSI_ESC ? '' : '33'
  # Yellow, alias for BROWN foreground
  F_YELLOW = SKIP_ANSI_ESC ? '' : F_BROWN
  # blue foreground
  F_BLUE = SKIP_ANSI_ESC ? '' : '34'
  # Purple foreground
  F_PURPLE = SKIP_ANSI_ESC ? '' : '35'
  # Magenta, alias or PURPLE foreground
  F_MAGENTA = SKIP_ANSI_ESC ? '' : F_PURPLE
  # Cyan foreground
  F_CYAN = SKIP_ANSI_ESC ? '' : '36'
  # Light Grey foreground
  F_LGREY = SKIP_ANSI_ESC ? '' : '37'
  # Light Gray, alias for GREY foreground
  F_LGRAY = SKIP_ANSI_ESC ? '' : F_LGREY
  # Dark Grey foreground
  F_DGREY = SKIP_ANSI_ESC ? '' : '90'
  # Dark Gray, alias for GRAY foreground
  F_DGRAY = SKIP_ANSI_ESC ? '' : F_DGREY

  # Light Red foreground
  F_LRED = SKIP_ANSI_ESC ? '' : '91'
  # Light Green foreground
  F_LGREEN = SKIP_ANSI_ESC ? '' : '92'
  # Light Brown foreground
  F_LBROWN = SKIP_ANSI_ESC ? '' : '93'
  # Light Yellow, alias for BROWN foreground
  F_LYELLOW = SKIP_ANSI_ESC ? '' : F_LBROWN
  # Light Blue foreground
  F_LBLUE = SKIP_ANSI_ESC ? '' : '94'
  # Light Purple foreground
  F_LPURPLE = SKIP_ANSI_ESC ? '' : '95'
  # Light Magenta, alias for PURPLE foreground
  F_LMAGENTA = SKIP_ANSI_ESC ? '' : F_LPURPLE
  # Light Cyan foreground
  F_LCYAN = SKIP_ANSI_ESC ? '' : '96'
  # Light White foreground
  F_WHITE = SKIP_ANSI_ESC ? '' : '97'

  # Close the ANSI Escape Sequence
  CL = SKIP_ANSI_ESC ? '' : 'm'

  # Black background
  B_BLACK = SKIP_ANSI_ESC ? '' : '40'
  # Red background
  B_RED = SKIP_ANSI_ESC ? '' : '41'
  # Green background
  B_GREEN = SKIP_ANSI_ESC ? '' : '42'
  # Brown background
  B_BROWN = SKIP_ANSI_ESC ? '' : '43'
  # Yellow, alias for BROWN background
  B_YELLOW = SKIP_ANSI_ESC ? '' : B_BROWN
  # Blue background
  B_BLUE = SKIP_ANSI_ESC ? '' : '44'
  # Purple background
  B_PURPLE = SKIP_ANSI_ESC ? '' : '45'
  # Magenta, alias for PURPLE background
  B_MAGENTA = SKIP_ANSI_ESC ? '' : B_PURPLE
  # Cyan background
  B_CYAN = SKIP_ANSI_ESC ? '' : '46'
  # Light Grey background
  B_LGREY = SKIP_ANSI_ESC ? '' : '47'
  # Light Gray, alias for GRAY background
  B_LGRAY = SKIP_ANSI_ESC ? '' : B_LGREY
  # Dark Grey background
  B_DGREY = SKIP_ANSI_ESC ? '' : '100'
  # Dark Gray, alias for GRAY background
  B_DGRAY = SKIP_ANSI_ESC ? '' : B_DGREY

  # Plain background
  B_PLAIN = SKIP_ANSI_ESC ? '' : '49'
  # Default background
  B_DEFAULT = SKIP_ANSI_ESC ? '' : B_PLAIN

  # Light Red background
  B_LRED = SKIP_ANSI_ESC ? '' : '101'
  # Light Green background
  B_LGREEN = SKIP_ANSI_ESC ? '' : '102'
  # Light Brown background
  B_LBROWN = SKIP_ANSI_ESC ? '' : '103'
  # Light Yellow, alias for BROWN background
  B_LYELLOW = SKIP_ANSI_ESC ? '' : B_LBROWN
  # Light Blue background
  B_LBLUE = SKIP_ANSI_ESC ? '' : '104'
  # Light Purple background
  B_LPURPLE = SKIP_ANSI_ESC ? '' : '105'
  # Light Magenta, alias for PURPLE background
  B_LMAGENTA = SKIP_ANSI_ESC ? '' : B_LPURPLE
  # Light Cyan background
  B_LCYAN = SKIP_ANSI_ESC ? '' : '106'
  # Light White background
  B_WHITE = SKIP_ANSI_ESC ? '' : '107'

  # All Styles with names
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

  # All Foregrounds with names
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

  # All Backgrounds with names
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

  # convenient test for all styles
  def test
    puts
    out = ''
    BACKS.keys.each { |b|
      FORES.keys.each { |f|
        STYLES.keys.each { |s|
          out << %<#{LLQBIG}#{OP}#{s};#{f};#{b}m#{FORES[f]}/#{BACKS[b]}:#{STYLES[s]}#{RESET}#{RRQBIG}>
          if out.length > 240
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

end
