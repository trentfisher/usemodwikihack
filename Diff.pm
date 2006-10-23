###############################################################################
#
#  Diff
#
#  Created by Michael Buschbeck <michael.buschbeck@bitshapers.com>
#  Free for use and modification.
#
#  Tools for getting the differences between two token lists or plain texts.
#
#  $Revision: 1.10 $
#  $Date: 2002/08/02 22:23:03 $
#

package Diff;


###############################################################################
#
#  diff @tokens1, @tokens2, [$countTokensMatch]
#
#  Performs a difference operation on two lists of tokens. Returns a list of
#  hash references that alternatingly describe stretches of tokens that are
#  identical in both input token lists and stretches of tokens that differ in
#  both lists. In detail, the structure of the output list is as follows:
#
#    type      Specifies what kind of range of tokens this element describes.
#
#                IDENT   Stretch of tokens that are identical in both lists,
#                        even though they might not be located at the same
#                        array indices.
#
#                DIFF    Stretch of tokens that aren't identical in both lists.
#
#    index1    Array index of the first token in the respective input token
#    index2    lists which are described by this output list element.
#
#    length1   Length of the token stretches described by this output list
#    length2   element. For output list elements that describe identical
#              stretches, these two parameters naturally have the same value.
#
#  The last parameter specifies how many tokens have to match after a
#  difference to indicate a matching stretch of tokens. For paragraph and word
#  comparisons, a single token might suffice; for character comparisons, a
#  value of an average word length might be a better choice. Defaults to a
#  single token if not specified.
#  

sub diff (\@\@;$) {

  my $refTokens1 = shift;
  my $refTokens2 = shift;
  my $countTokensMatch = shift;

  my @result;
  
  $countTokensMatch = 1
    unless defined $countTokensMatch
    and $countTokensMatch > 0;
  
  my %indexToken;
  my $indexToken1 = 0;
  my $indexToken2 = 0;
  my $lengthLongword = length pack 'L';
  
  while ($indexToken1 < @$refTokens1 and
         $indexToken2 < @$refTokens2) {

    my $countTokens1 = 0;
    my $countTokens2 = 0;

    while ($indexToken1 + $countTokens1 < @$refTokens1 and 
           $indexToken2 + $countTokens2 < @$refTokens2 and 
           $refTokens1->[$indexToken1 + $countTokens1] eq
           $refTokens2->[$indexToken2 + $countTokens2]) {

      $countTokens1++;
      $countTokens2++;
      }

    if ($countTokens1 > 0) {
      push @result, {
        type   => IDENT,
        index1 => $indexToken1, length1 => $countTokens1,
        index2 => $indexToken2, length2 => $countTokens2,
        };
      }

    $indexToken1 += $countTokens1;
    $indexToken2 += $countTokens2;

    last
      if  $indexToken1 >= @$refTokens1
      and $indexToken2 >= @$refTokens2;

    if (not %indexToken) {
      my $tokensMatch;

      for (my $indexToken = 0; $indexToken < $countTokensMatch; $indexToken++) {
        my $token = $refTokens1->[$indexToken1 + $indexToken];
        last unless defined $token;
        $tokensMatch .= pack 'L/a*', $token;
        }
      
      for (my $indexToken = $indexToken1; $indexToken < @$refTokens1; $indexToken++) {
        $indexToken{$tokensMatch} .= pack 'L', $indexToken;
  
        my $token = $refTokens1->[$indexToken + $countTokensMatch];
        $tokensMatch = (substr $tokensMatch, (unpack 'L', $tokensMatch) + $lengthLongword) .
                       (defined $token ? pack 'L/a*', $token : '');
        }
      }
    
    my $countTokensMatch1;
    my $countTokensMatch2;
    my $sumCountTokens;
    my $difCountTokens;
    
    undef $countTokens1;
    undef $countTokens2;

    my $tokensMatch;

    for (my $indexToken = 0; $indexToken < $countTokensMatch; $indexToken++) {
      my $token = $refTokens2->[$indexToken2 + $indexToken];
      last unless defined $token;
      $tokensMatch .= pack 'L/a*', $token;
      }

    my $countTokensMatchMax2 = @$refTokens2 - $indexToken2;
    for ($countTokensMatch2 = 0; $countTokensMatch2 < $countTokensMatchMax2; $countTokensMatch2++) {
      my $listIndexToken = $indexToken{$tokensMatch};

      if (defined $listIndexToken) {
        $listIndexToken = substr $listIndexToken, $lengthLongword
          while length $listIndexToken
          and $indexToken1 > unpack 'L', $listIndexToken;
          
        if (length $listIndexToken) {
          $countTokensMatch1 = (unpack 'L', $listIndexToken) - $indexToken1;
          
          my $sumCountTokensMatch =     $countTokensMatch1 + $countTokensMatch2;
          my $difCountTokensMatch = abs($countTokensMatch1 - $countTokensMatch2);
          
          if (not defined $sumCountTokens
              or  $sumCountTokensMatch <  $sumCountTokens
              or ($sumCountTokensMatch == $sumCountTokens
                  and $difCountTokensMatch < $difCountTokens)) {
    
            $countTokens1 = $countTokensMatch1;
            $countTokens2 = $countTokensMatch2;
            $sumCountTokens = $sumCountTokensMatch;
            $difCountTokens = $difCountTokensMatch;
            }
          }
        }
      
      my $token = $refTokens2->[$indexToken2 + $countTokensMatch2 + $countTokensMatch];
      $tokensMatch = (substr $tokensMatch, (unpack 'L', $tokensMatch) + $lengthLongword) .
                     (defined $token ? pack 'L/a*', $token : '');

      last
        if defined $sumCountTokens
        and $countTokensMatch2 > $sumCountTokens;
      }

    $countTokens1 = @$refTokens1 - $indexToken1 unless defined $countTokens1;
    $countTokens2 = @$refTokens2 - $indexToken2 unless defined $countTokens2;

    push @result, {
      type   => DIFF,
      index1 => $indexToken1, length1 => $countTokens1,
      index2 => $indexToken2, length2 => $countTokens2,
      };

    $indexToken1 += $countTokens1;
    $indexToken2 += $countTokens2;
    }

  return @result;
  }


###############################################################################
#
#  diffClassic $textOld, $textNew
#
#  Performs a diff on the two given texts and returns a string looking like
#  the default output of the classic diff command-line tool called without any
#  command line switches. This output can be used to apply a patche on the
#  unaltered old version of the text.
#

###########################################################
#
#  diffClassicRange $indexRange, $lengthRange
#
#  Helper function. Returns a string describing a range of
#  lines in diff style.
#

sub diffClassicRange ($$) {

  my $indexRange = shift;
  my $lengthRange = shift;

  return sprintf '%d', $indexRange + 1
    if $lengthRange == 1;
  
  return sprintf '%d,%d', $indexRange + 1, $indexRange + $lengthRange;
  }


###########################################################
#
#  diffClassicCount @countNewlines, $indexPara, $countPara
#
#  Helper function. Returns the number of lines
#  represented by the given range of paragraphs.
#

sub diffClassicCount (\@$$) {

  my $refCountNewlines = shift;
  my $indexPara = shift;
  my $countPara = shift;
  
  my $countLines = 0;
  map $countLines += ($refCountNewlines->[$_] or 1),
    $indexPara .. $indexPara + $countPara - 1;
  
  return $countLines;
  }


###########################################################
#
#  diffClassicConcat @para, @countNewlines,
#                    $indexPara, $countPara, $textPrefix
#
#  Helper function. Returns the concatenated string of
#  the specified range of lines, each line prefixed by
#  the given prefix string.
#

sub diffClassicConcat (\@\@$$$) {

  my $refPara = shift;
  my $refCountNewlines = shift;
  my $indexPara = shift;
  my $countPara = shift;
  my $textPrefix = shift;
  
  my $result;
  for my $indexPara ($indexPara .. $indexPara + $countPara - 1) {
    $result .=  $textPrefix . $refPara->[$indexPara] . "\n";
    $result .= "$textPrefix\n" x ($refCountNewlines->[$indexPara] - 1);
    }
  
  return $result;
  }


###########################################################
#
#  diffClassic $textOld, $textNew
#
#  Returns a diff result like the diff command-line tool
#  does. See main comment header for details.
#

sub diffClassic ($$) {
  
  my $textOld = shift;
  my $textNew = shift;
  
  my @paraOld = $textOld =~ /([^\x0a\x0d]*[\x0a\x0d]*)/g;
  my @paraNew = $textNew =~ /([^\x0a\x0d]*[\x0a\x0d]*)/g;
  
  my @countNewlinesOld = map s/(?:\x0a\x0d|\x0a|\x0d\x0a|\x0d)//g, @paraOld;
  my @countNewlinesNew = map s/(?:\x0a\x0d|\x0a|\x0d\x0a|\x0d)//g, @paraNew;

  my $result;
  my $indexLineOld = 0;
  my $indexLineNew = 0;
  
  foreach my $diffPara (diff @paraOld, @paraNew) {
    my $countLinesOld = diffClassicCount @countNewlinesOld, $diffPara->{index1}, $diffPara->{length1};
    my $countLinesNew = diffClassicCount @countNewlinesNew, $diffPara->{index2}, $diffPara->{length2};
 
    if ($diffPara->{type} eq DIFF) {
      my $countNewlinesTrailing = 0;
      my $countNewlinesTrailingOld = $countNewlinesOld[$diffPara->{index1} + $diffPara->{length1} - 1];
      my $countNewlinesTrailingNew = $countNewlinesNew[$diffPara->{index2} + $diffPara->{length2} - 1];
    
      if ($diffPara->{length1} > 0 and $countNewlinesTrailingOld > 1 and
          $diffPara->{length2} > 0 and $countNewlinesTrailingNew > 1) {

        $countNewlinesTrailing = ($countNewlinesTrailingOld < $countNewlinesTrailingNew ?
                                  $countNewlinesTrailingOld : $countNewlinesTrailingNew) - 1;

        $countNewlinesOld[$diffPara->{index1} + $diffPara->{length1} - 1] -= $countNewlinesTrailing;
        $countNewlinesNew[$diffPara->{index2} + $diffPara->{length2} - 1] -= $countNewlinesTrailing;
        }
    
      my $textRangeOld = diffClassicRange $indexLineOld, $countLinesOld - $countNewlinesTrailing;
      my $textRangeNew = diffClassicRange $indexLineNew, $countLinesNew - $countNewlinesTrailing;
      
         if ($countLinesOld == 0) { $result .= sprintf "%da%s\n", $indexLineOld, $textRangeNew }
      elsif ($countLinesNew == 0) { $result .= sprintf "%sd%d\n", $textRangeOld, $indexLineNew }
      else                        { $result .= sprintf "%sc%s\n", $textRangeOld, $textRangeNew }
      
      $result .= diffClassicConcat @paraOld, @countNewlinesOld, $diffPara->{index1}, $diffPara->{length1}, '< '
        if $diffPara->{length1} > 0; # $countLinesOld > 0;
  
      $result .= "---\n"
        if  $countLinesOld > 0
        and $countLinesNew > 0;
  
      $result .= diffClassicConcat @paraNew, @countNewlinesNew, $diffPara->{index2}, $diffPara->{length2}, '> '
        if $diffPara->{length2} > 0; # $countLinesNew > 0;
      }
    
    $indexLineOld += $countLinesOld;
    $indexLineNew += $countLinesNew;
    }
  
  return (defined $result ? $result : '');
  }


###############################################################################
#
#  diffText $textOld, $textNew, %format
#
#  Compares two strings of plain text and returns a textual representation of
#  the diff output. The output is based on the following templates which are
#  stored in the hash that is passed as the last parameter:
#
#    paraIdent       Templates for paragraphs or stretches of paragraphs that
#    paraAdded       are identical in both texts, have been added to the old
#    paraDeleted     text, have been deleted from the old text or have been
#    paraChanged     changed in respect to the old text. The paraReplaced
#    paraReplaced    template is used instead of a combination of paraDeleted
#                    and paraAdded if it is specified and a deleted and an
#                    added paragraph immediately follow each other.
#
#    spanIdent       Templates for words within changed paragraphs that are
#    spanAdded       identical in both paragraphs, have been added to the old
#    spanDeleted     paragraph, or have been deleted from the old paragraph.
#
#    changeHeader    Header for changed text areas. The %oldFrom% and %newFrom%
#                    placeholders are substituted. Used only if changeContext
#                    is specified too.
#
#    changeContext   Number of paragraphs of unchanged text that are included
#                    in the output around changed text areas. If not specified,
#                    all paragraphs are included.
#
#    processText     Optional reference to a sub that preprocesses the text
#                    before it is inserted into the templates. The raw text is
#                    passed as the first argument and the processed text is
#                    expected back as the sub's return value.
#
#  Every para template can contain one or more of the following placeholders:
#
#    %text%          Text of the respective paragraph.
#
#    %textAdded%     Used in the paraReplaced template only for text that has
#    %textDeleted%   been added to or removed from the old version.
#
#    %oldFrom%       Start and end index and length of the affected stretch of
#    %oldTo%         paragraphs, in respect to the old text.
#    %oldLength%   
#
#    %newFrom%       Same as above, but in respect to the new text.
#    %newTo%
#    %newLength%   
#
#  Every span template can contain one or more of the following placeholders:
#
#    %text%          Text span that has remained identical, has been added or
#                    has been deleted.
#

###########################################################
#
#  diffTextSubstPara %position, $textSubst, $textTemplate
#
#  Helper function. Substitutes the various placeholders
#  in the given template by the appropriate values and
#  returns the result. Specify a hash reference as the
#  second argument if multiple text placeholders need to
#  be replaced.
#

sub diffTextSubstPara (\%$$) {

  my $refPosition = shift;
  my $textSubst = shift;
  my $textTemplate = shift;
  
  return ''
    unless defined $textSubst    and length $textSubst
    and    defined $textTemplate and length $textTemplate;

  $textTemplate =~ s[%oldFrom%]   [$refPosition->{index1} + 1                      ]ge;
  $textTemplate =~ s[%oldTo%]     [$refPosition->{index1} + $refPosition->{length1}]ge;
  $textTemplate =~ s[%oldLength%] [                         $refPosition->{length1}]ge;

  $textTemplate =~ s[%newFrom%]   [$refPosition->{index2} + 1                      ]ge;
  $textTemplate =~ s[%newTo%]     [$refPosition->{index2} + $refPosition->{length2}]ge;
  $textTemplate =~ s[%newLength%] [                         $refPosition->{length2}]ge;
  
  my $refSubst = ref $textSubst ? $textSubst : { text => $textSubst };
  my $patternSubst = join '|', keys %$refSubst;
  $textTemplate =~ s[%($patternSubst)%] [$refSubst->{$1}]g;
    
  return $textTemplate;
  }


###########################################################
#
#  diffTextSubstSpan $textSubst, $textTemplate
#
#  Helper function. Substitutes the text placeholder in
#  the given template by the given text and returns the
#  result.
#

sub diffTextSubstSpan ($$) {

  my $textSubst = shift;
  my $textTemplate = shift;
  
  return ''
    unless defined $textSubst    and length $textSubst
    and    defined $textTemplate and length $textTemplate;

  $textTemplate =~ s[%text%] [$textSubst]g;
  
  return $textTemplate;
  }


###########################################################
#
#  diffTextSubstHeader %position, $textTemplate
#
#  Helper function. Substitutes the various placeholders
#  in the given template by the appropriate values and
#  returns the result.
#

sub diffTextSubstHeader (\%$) {

  my $refPosition = shift;
  my $textTemplate = shift;
  
  return ''
    unless defined $textTemplate and length $textTemplate;
  
  $textTemplate =~ s[%oldFrom%] [$refPosition->{index1} + 1]ge;
  $textTemplate =~ s[%newFrom%] [$refPosition->{index2} + 1]ge;
    
  return $textTemplate;
  }


###########################################################
#
#  diffTextConcat @tokens, $indexToken, $countTokens
#
#  Helper function. Concatenates a given range of tokens
#  and returns the result.
#

sub diffTextConcat (\@$$) {

  my $refTokens = shift;
  my $indexToken = shift;
  my $countTokens = shift;
  
  return join '', @{$refTokens}[$indexToken .. $indexToken + $countTokens - 1];
  }


###########################################################
#
#  diffTextConcatPara @para, @countNewlines,
#                     $indexPara, $countPara
#
#  Helper function. Concatenates a given range of
#  paragraphs including their trailing newlines and
#  returns the result.
#

sub diffTextConcatPara (\@\@$$) {

  my $refPara = shift;
  my $refCountNewlines = shift;
  my $indexPara = shift;
  my $countPara = shift;
  
  return join '', map $refPara->[$_] . ("\n" x $refCountNewlines->[$_]),
    $indexPara .. $indexPara + $countPara - 1;
  }


###########################################################
#
#  diffText $textOld, $textNew, %format
#
#  Compares two versions of a plain-text document. See
#  main comment header for details.
#

sub diffText ($$\%) {

  my $textOld = shift;
  my $textNew = shift;
  my $refFormat = shift;
  
  my @paraOld = $textOld =~ /([^\x0a\x0d]*[\x0a\x0d]*)/g;
  my @paraNew = $textNew =~ /([^\x0a\x0d]*[\x0a\x0d]*)/g;

  my @countNewlinesOld = map s/(?:\x0a\x0d|\x0a|\x0d\x0a|\x0d)//g, @paraOld;
  my @countNewlinesNew = map s/(?:\x0a\x0d|\x0a|\x0d\x0a|\x0d)//g, @paraNew;
  
  my @diffPara = diff @paraOld, @paraNew, 2;

  my @wordsOld;
  my @wordsNew;
  my $textWordsOld;
  my $textWordsNew;
  my @diffWord;

  my %positionAccu;
  my $textParaAccuIdent;
  my $textParaAccuAdded;
  my $textParaAccuDeleted;
  my $textParaAccuChanged;
  my $flagParaChangedPrev;

  $positionAccu{index1} = 0;  $positionAccu{length1} = 0;
  $positionAccu{index2} = 0;  $positionAccu{length2} = 0;

  my $codeProcessText;
  $codeProcessText = $refFormat->{processText};
  $codeProcessText = sub { shift }
    unless defined $codeProcessText;

  my $result;

  while (my $diffPara = shift @diffPara) {
    my %positionCurrent;
    my $textParaCurrentIdent;
    my $textParaCurrentChanged;
    my $textParaCurrentAdded;
    my $textParaCurrentDeleted;
    
    if (@diffWord) {
      my $flagParaCompleted;
      my $lengthIdent   = 0;
      my $lengthChanged = 0;
    
      while (@diffWord) {
        my $diffWord = $diffWord[0];

        $textWordsOld = diffTextConcat @wordsOld, $diffWord->{index1}, $diffWord->{length1} unless defined $textWordsOld;
        $textWordsNew = diffTextConcat @wordsNew, $diffWord->{index2}, $diffWord->{length2} unless defined $textWordsNew;

        my ($lengthParaChunkOld, $textParaChunkOld);
        my ($lengthParaChunkNew, $textParaChunkNew);
        
        $lengthParaChunkOld = $+[0] if $textWordsOld =~ /[^\n]*(\n?)/ and ($1 or $diffWord->{index1} + $diffWord->{length1} == @wordsOld);
        $lengthParaChunkNew = $+[0] if $textWordsNew =~ /[^\n]*(\n?)/ and ($1 or $diffWord->{index2} + $diffWord->{length2} == @wordsNew);

        if ($diffWord->{type} eq IDENT) {
          undef $lengthParaChunkOld, undef $lengthParaChunkNew
            unless defined $lengthParaChunkOld
            and    defined $lengthParaChunkNew;
          }
        
        else {
          undef $lengthParaChunkOld, undef $lengthParaChunkNew
            if defined $lengthParaChunkOld != defined $lengthParaChunkNew
            and (defined $textParaCurrentAdded or defined $textParaCurrentDeleted);
          
          $lengthParaChunkOld = 0 if not defined $lengthParaChunkOld and defined $lengthParaChunkNew;
          $lengthParaChunkNew = 0 if not defined $lengthParaChunkNew and defined $lengthParaChunkOld;
          }

        $flagParaCompleted = defined $lengthParaChunkOld;

        $lengthParaChunkOld = length $textWordsOld unless defined $lengthParaChunkOld;
        $lengthParaChunkNew = length $textWordsNew unless defined $lengthParaChunkNew;

        $textParaChunkOld = substr $textWordsOld, 0, $lengthParaChunkOld;
        $textParaChunkNew = substr $textWordsNew, 0, $lengthParaChunkNew;
        $textWordsOld     = substr $textWordsOld,    $lengthParaChunkOld;
        $textWordsNew     = substr $textWordsNew,    $lengthParaChunkNew;

        if ($diffWord->{type} eq IDENT) { 
          $textParaCurrentChanged .= (diffTextSubstSpan &$codeProcessText($textParaChunkOld), $refFormat->{spanIdent});
          $textParaCurrentAdded   .=                                      $textParaChunkOld;
          $textParaCurrentDeleted .=                                      $textParaChunkOld;

          $lengthIdent += length $textParaChunkOld;
          $lengthIdent -= $textParaChunkOld =~ tr/\n//;
          }
        
        else {
          $textParaCurrentChanged .= (diffTextSubstSpan &$codeProcessText($textParaChunkOld), $refFormat->{spanDeleted})
                                  .  (diffTextSubstSpan &$codeProcessText($textParaChunkNew), $refFormat->{spanAdded});
          $textParaCurrentAdded   .=                                      $textParaChunkNew;
          $textParaCurrentDeleted .=                                      $textParaChunkOld;

          $lengthChanged += (length $textParaChunkNew < length $textParaChunkOld ?
                             length $textParaChunkNew : length $textParaChunkOld);
          }

        if (not length $textWordsOld and
            not length $textWordsNew) {
          shift @diffWord;
          undef $textWordsOld;
          undef $textWordsNew;
          }

        last if $flagParaCompleted;
        }

      $positionCurrent{length1} = ($textParaCurrentDeleted =~ /[^\n]/ ? 1 : 0);
      $positionCurrent{length2} = ($textParaCurrentAdded   =~ /[^\n]/ ? 1 : 0);

      if (defined $textParaCurrentAdded   and
          defined $textParaCurrentDeleted and $textParaCurrentAdded eq $textParaCurrentDeleted) {

        $textParaCurrentIdent = $textParaCurrentAdded;

        undef $textParaCurrentChanged;
        undef $textParaCurrentAdded;
        undef $textParaCurrentDeleted;
        }
      
      elsif (defined $textParaCurrentChanged) {
        undef $textParaCurrentAdded   unless length $textParaCurrentAdded;
        undef $textParaCurrentDeleted unless length $textParaCurrentDeleted;
        
        if (defined $textParaCurrentAdded   and
            defined $textParaCurrentDeleted and $lengthIdent > $lengthChanged) {
          undef $textParaCurrentAdded;
          undef $textParaCurrentDeleted;
          }
        
        else {
          undef $textParaCurrentChanged;
          }
        }
      }
    
    elsif (defined $diffPara) {
      if ($diffPara->{type} eq IDENT) {
        my $countPara = 0;
        my $deltaCountNewlines;
        
        while ($countPara < $diffPara->{length1}) {
          $deltaCountNewlines = $countNewlinesNew[$diffPara->{index2} + $countPara] -
                                $countNewlinesOld[$diffPara->{index1} + $countPara];
          $countPara++;
          last unless $deltaCountNewlines == 0;
          }

        if ($deltaCountNewlines != 0) {
          my $textParaIdent;
             if ($deltaCountNewlines > 0) { $textParaIdent = diffTextConcatPara @paraOld, @countNewlinesOld, $diffPara->{index1}, $countPara }
          elsif ($deltaCountNewlines < 0) { $textParaIdent = diffTextConcatPara @paraNew, @countNewlinesNew, $diffPara->{index2}, $countPara }
        
          @wordsOld = ($textParaIdent);  push @wordsOld, "\n" x -$deltaCountNewlines if $deltaCountNewlines < 0;
          @wordsNew = ($textParaIdent);  push @wordsNew, "\n" x  $deltaCountNewlines if $deltaCountNewlines > 0;
          
          @diffWord = ({ type => IDENT, index1 => 0, index2 => 0, length1 => 1,             length2 => 1 },
                       { type => DIFF,  index1 => 1, index2 => 1, length1 => @wordsOld - 1, length2 => @wordsNew - 1 });
          }

        else {
          $textParaCurrentIdent = diffTextConcatPara @paraNew, @countNewlinesNew, $diffPara->{index2}, $countPara;
          }
        
        if ($countPara < $diffPara->{length1}) {
          $diffPara->{index1} += $countPara;  $diffPara->{length1} -= $countPara;
          $diffPara->{index2} += $countPara;  $diffPara->{length2} -= $countPara;
          unshift @diffPara, $diffPara;
          }
        }
      
      else {
        my $textParaOld = diffTextConcatPara @paraOld, @countNewlinesOld, $diffPara->{index1}, $diffPara->{length1};
        my $textParaNew = diffTextConcatPara @paraNew, @countNewlinesNew, $diffPara->{index2}, $diffPara->{length2};
      
           if ($diffPara->{length1} == 0) { $textParaCurrentAdded   = $textParaNew }
        elsif ($diffPara->{length2} == 0) { $textParaCurrentDeleted = $textParaOld }
        else {
          @wordsOld = map((/^\n/ ? ($_, ('') x 4) : $_), $textParaOld =~ /(\w+|\W)/g);
          @wordsNew = map((/^\n/ ? ($_, ('') x 4) : $_), $textParaNew =~ /(\w+|\W)/g);
          @diffWord = diff @wordsOld, @wordsNew, 5;
          }
        }
      
      if (not @diffWord or defined $textParaCurrentIdent) {
        $positionCurrent{length1} = $diffPara->{length1};
        $positionCurrent{length2} = $diffPara->{length2};
        }
      }
    
    if ((not defined $diffPara
         or defined $textParaCurrentIdent
         or defined $textParaCurrentChanged
         or defined $textParaCurrentAdded
         or defined $textParaCurrentDeleted)
        and (   (defined $textParaAccuIdent   and not defined $textParaCurrentIdent)
             or (defined $textParaAccuChanged and not defined $textParaCurrentChanged)
             or (        (defined $textParaAccuAdded    or defined $textParaAccuDeleted)
                 and not (defined $textParaCurrentAdded or defined $textParaCurrentDeleted)))) {

      if (defined $refFormat->{changeContext}) {
        if (defined $textParaAccuIdent) {
          my @paraAccuIdent = $textParaAccuIdent =~ /(\n*[^\n]+\n*)/g;

          my $countParaAccuIdent = @paraAccuIdent;
          my $countParaAccuIdentTrailer;
          my $countParaAccuIdentLeader;
          
          if (not defined $result) {
            $countParaAccuIdentLeader = $refFormat->{changeContext};
            $countParaAccuIdentLeader = $countParaAccuIdent
              if $countParaAccuIdentLeader > $countParaAccuIdent;
            }
          
          elsif (not defined $diffPara               and
                 not defined $textParaCurrentAdded   and
                 not defined $textParaCurrentDeleted and
                 not defined $textParaCurrentChanged) {
            $countParaAccuIdentTrailer = $refFormat->{changeContext};
            $countParaAccuIdentTrailer = $countParaAccuIdent
              if $countParaAccuIdentTrailer > $countParaAccuIdent;
            }
          
          else {
            $countParaAccuIdentTrailer = $refFormat->{changeContext};
            $countParaAccuIdentLeader  = $refFormat->{changeContext};
            }

          $countParaAccuIdentTrailer--
            if defined $countParaAccuIdentTrailer and $countParaAccuIdentTrailer > 0
            and $flagParaChangedPrev;
          $countParaAccuIdentLeader--
            if defined $countParaAccuIdentLeader and $countParaAccuIdentLeader > 0
            and defined $textParaCurrentChanged;

          if (defined $countParaAccuIdentTrailer and
              defined $countParaAccuIdentLeader  and
              $countParaAccuIdentTrailer + $countParaAccuIdentLeader >= $countParaAccuIdent) {
            undef $countParaAccuIdentLeader;
            undef $countParaAccuIdentTrailer;
            }

          if (defined $countParaAccuIdentTrailer) {
            my %positionAccuTrailer = %positionAccu;
            $positionAccuTrailer{length1} = $countParaAccuIdentTrailer;
            $positionAccuTrailer{length2} = $countParaAccuIdentTrailer;

            my $textParaAccuIdentTrailer;
            $textParaAccuIdentTrailer = diffTextConcat @paraAccuIdent, 0, $countParaAccuIdentTrailer;
            $textParaAccuIdentTrailer =~ s/\n+$/\n/;

            $result .= diffTextSubstPara %positionAccuTrailer,
                       &$codeProcessText($textParaAccuIdentTrailer), $refFormat->{paraIdent};
            
            undef $textParaAccuIdent
              unless defined $countParaAccuIdentLeader;
            }

          if (defined $countParaAccuIdentLeader
              and (   defined $diffPara or @diffWord
                   or defined $textParaCurrentAdded
                   or defined $textParaCurrentDeleted
                   or defined $textParaCurrentChanged)) {
          
            $positionAccu{index1} += $positionAccu{length1} - $countParaAccuIdentLeader;
            $positionAccu{index2} += $positionAccu{length2} - $countParaAccuIdentLeader;
            $positionAccu{length1} = $countParaAccuIdentLeader;
            $positionAccu{length2} = $countParaAccuIdentLeader;

            $result .= diffTextSubstHeader %positionAccu, $refFormat->{changeHeader};

            $textParaAccuIdent = diffTextConcat @paraAccuIdent,
              $countParaAccuIdent - $countParaAccuIdentLeader, $countParaAccuIdentLeader;
            }

          else {
            undef $textParaAccuIdent
              if defined $countParaAccuIdentLeader
              or defined $countParaAccuIdentTrailer;
            }
          }
        
        elsif (not defined $result) {
          $result .= diffTextSubstHeader %positionAccu, $refFormat->{changeHeader};
          }
        }

      $flagParaChangedPrev = defined $textParaAccuChanged;

      $result .= diffTextSubstPara %positionAccu, &$codeProcessText($textParaAccuIdent),  $refFormat->{paraIdent}   if defined $textParaAccuIdent;
      $result .= diffTextSubstPara %positionAccu,                   $textParaAccuChanged, $refFormat->{paraChanged} if defined $textParaAccuChanged;

      my $countNewlinesIdent;
      if (defined $textParaAccuAdded and
          defined $textParaAccuDeleted) {
        my $countNewlinesAdded   = 0;
        my $countNewlinesDeleted = 0;
          
        $textParaAccuAdded   =~ s/(^|\n)(\n*)$/$1/s and $countNewlinesAdded   = length $2;
        $textParaAccuDeleted =~ s/(^|\n)(\n*)$/$1/s and $countNewlinesDeleted = length $2;

        my $deltaCountNewlines;
        $deltaCountNewlines =  $countNewlinesAdded - $countNewlinesDeleted;
        $countNewlinesIdent = ($countNewlinesAdded < $countNewlinesDeleted ?
                               $countNewlinesAdded : $countNewlinesDeleted);

        $textParaAccuAdded   .= "\n" x  $deltaCountNewlines if $deltaCountNewlines > 0;
        $textParaAccuDeleted .= "\n" x -$deltaCountNewlines if $deltaCountNewlines < 0;
        
        undef $textParaAccuAdded   unless length $textParaAccuAdded;
        undef $textParaAccuDeleted unless length $textParaAccuDeleted;
        }

      if (defined $textParaAccuAdded and
          defined $textParaAccuDeleted and defined $refFormat->{paraReplaced}) {
        my $refSubst = { textAdded   => &$codeProcessText($textParaAccuAdded),
                         textDeleted => &$codeProcessText($textParaAccuDeleted) };
        $result .= diffTextSubstPara %positionAccu, $refSubst, $refFormat->{paraReplaced};
        }

      else {
        $result .= diffTextSubstPara %positionAccu, &$codeProcessText($textParaAccuDeleted), $refFormat->{paraDeleted} if defined $textParaAccuDeleted;
        $result .= diffTextSubstPara %positionAccu, &$codeProcessText($textParaAccuAdded),   $refFormat->{paraAdded}   if defined $textParaAccuAdded;
        }

      undef $textParaAccuIdent;
      undef $textParaAccuChanged;
      undef $textParaAccuAdded;
      undef $textParaAccuDeleted;
      
      $textParaAccuIdent = "\n" x $countNewlinesIdent
        if defined $countNewlinesIdent;

      $positionAccu{index1} += $positionAccu{length1};  $positionAccu{length1} = 0;
      $positionAccu{index2} += $positionAccu{length2};  $positionAccu{length2} = 0;
      }
    
    $textParaAccuIdent   .= $textParaCurrentIdent   if defined $textParaCurrentIdent;
    $textParaAccuChanged .= $textParaCurrentChanged if defined $textParaCurrentChanged;
    $textParaAccuAdded   .= $textParaCurrentAdded   if defined $textParaCurrentAdded;
    $textParaAccuDeleted .= $textParaCurrentDeleted if defined $textParaCurrentDeleted;
    
    $positionAccu{length1} += $positionCurrent{length1} if defined $positionCurrent{length1};
    $positionAccu{length2} += $positionCurrent{length2} if defined $positionCurrent{length2};
    
    if (not @diffPara and defined $diffPara) {
      undef $diffPara;
      redo;
      }

    redo if @diffWord;
    }

  return (defined $result ? $result : '');
  }


###############################################################################

1;
