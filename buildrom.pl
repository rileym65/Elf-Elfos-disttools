#!/usr/bin/perl -w 

use strict;

my $line;
my $line2;
my @args;
my $offset;
my $outLine;
my $outCount;
my $table;
my @values;
my $value;
my $lastAddr;

sub readByte {
  my $value;
  if (defined($value = shift(@values))) {
    return hex($value);
    } 
  $line = <FIL>;
  chomp($line);
print("-->$line\n");
  @values = split(/  */,$line);
  shift(@values);
  return hex(shift(@values));
  }

sub outByte {
  my $value = shift;
  my $aValue = sprintf(" %02x",$value);
  $table++;
  $outLine .= $aValue;
  $outCount++;
  if ($outCount == 16) {
    print TABF $outLine,"\n";
    $outLine = sprintf(":%04x",$table);
    $outCount = 0;
    }
  }

sub processHeader {
  my $value;
  my $start;
  my $i;
  $line = <FIL>;
  chomp($line);
  $line2 = <FIL>;
  chomp($line2);
  $line2 = substr $line2, 5;
  $line = $line . $line2;
  @values = split(/  */,$line);
  shift(@values);
  shift(@values);
  shift(@values);
  shift(@values);
  while (($value = readByte()) != 0) {
    outByte($value);
    }
  outByte(0);
  outByte($offset / 256);
  outByte($offset % 256);
  $start = readByte() * 256;
  $start += readByte();
  $offset -= $start;
  $value = readByte() * 256;
  $value += readByte();
  $value += $offset;
  outByte($value / 256);
  outByte($value % 256);
  for ($i=0; $i<6; $i++) {
    outByte(readByte());
    }
  readByte();
  }

$table = hex("8003");
$outLine = sprintf(":%04x",$table);
$outCount = 0;

open OUTF,">build.rom";
open TABF,">table.rom";
open INF,"<rom.txt";

print TABF ":8000 c0 d0 00\n";

while (<INF>) {
  chomp;
  print $_;
  $line = $_;
  @args = split(/  */,$line);
  if ($args[0] eq "PROG") {
    open FIL,"<$args[1]";
    while (<FIL>) {
      if ($_ !~ /^\*/) { print OUTF $_; }
      }
    close FIL;
    }
  if ($args[0] eq "MOD") {
    $offset = hex($args[2]);
    open FIL,"<$args[1]";
    processHeader();
    while (<FIL>) {
      if ($_ !~ /^\*/) {
        chomp;
        $line = $_;
        $value = substr($line,1,4);
        $value = hex($value) + $offset;
        $lastAddr = $value;
        printf OUTF ":%04x",$value;
        print  OUTF substr($line,5),"\n";
        }
      }
    printf "  %04x",$lastAddr+16;
    close FIL;
    }
  print "\n";
  }

outByte(0);
if ($outCount != 0) {
  print TABF $outLine,"\n";
  }

close INF;
close OUTF;
close TABF;

