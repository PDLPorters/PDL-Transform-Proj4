use strict;
use warnings;
use PDL;
use PDL::Transform::Proj4;
use Test::More;

# Test integration with PDL::Transform

my $im = sequence(2048,1024)/2048/1024*255.99;
$im = $im->byte;
my $h = $im->fhdr;

$h->{SIMPLE} = 'T';
$h->{NAXIS} = 3;
$h->{NAXIS1}=2048;          $h->{CRPIX1}=1024.5;    $h->{CRVAL1}=0;
$h->{NAXIS2}=1024;          $h->{CRPIX2}=512.5;     $h->{CRVAL2}=0;
$h->{NAXIS3}=3,             $h->{CRPIX3}=1;         $h->{CRVAL3}=0;
$h->{CTYPE1}='Longitude';   $h->{CUNIT1}='degrees'; $h->{CDELT1}=180/1024.0;
$h->{CTYPE2}='Latitude';    $h->{CUNIT2}='degrees'; $h->{CDELT2}=180/1024.0;
$h->{CTYPE3}='RGB';         $h->{CUNIT3}='index';   $h->{CDELT3}=1.0;
$h->{COMMENT}='Plate Caree Projection';
$h->{HISTORY}='PDL Distribution Image, derived from NASA/MODIS data',

$im->hdrcpy(1);
$im->badflag(1);

SKIP: {

   my $map = $im->copy;

   my $map_size = [500,500];

   my @slices = (
      "245:254,68:77,(0)",
      "128:137,272:281,(0)",
      "245:254,262:271,(0)",
      "390:399,245:254,(0)",
      "271:280,464:473,(0)"
   );


   ##############
   # TESTS 1-5: #
   ##############
   # Get EQC reference data:
   my @ref_eqc_slices = get_ref_eqc_slices();

   # Check EQC map against reference:
   my $eqc_opts = "+proj=eqc +lon_0=0 +datum=WGS84";
   my $eqc = eval { $map->map( t_proj( proj_params => $eqc_opts ), $map_size ) };
   if (! defined($eqc)) {
      diag("PROJ4 error: $@\n");
      skip "Possible bad PROJ4 install",20 if $@ =~ m/Projection initialization failed/;
   }
   foreach my $i ( 0 .. $#slices )
   {
      my $str = $slices[$i];
      my $slice = $eqc->slice($str);
      is( "$slice", $ref_eqc_slices[$i], "check ref_eqc for slices[$i]" );
   }

   ###############
   # TESTS 6-10: #
   ###############
   # Get Ortho reference data:
   my @ref_ortho_slices = get_ref_ortho_slices();

   # Check Ortho map against reference:
   my $ortho_opts = "+proj=ortho +ellps=WGS84 +lon_0=-90 +lat_0=40";
   my $ortho = $map->map( t_proj( proj_params => $ortho_opts ), $map_size );
   foreach my $i ( 0 .. $#slices )
   {
      my $str = $slices[$i];
      my $slice = $ortho->slice($str);
      is( "$slice", $ref_ortho_slices[$i], "check ref_ortho for slices[$i]" );
   }

   #
   # Test the auto-generated methods:
   #
   ################
   # TESTS 11-15: #
   ################
   my $ortho2 = $map->map( t_proj_ortho( ellps => 'WGS84', lon_0 => -90, lat_0 => 40 ), $map_size );
   foreach my $i ( 0 .. $#slices )
   {
      my $str = $slices[$i];
      my $slice = $ortho2->slice($str);
      is( "$slice", $ref_ortho_slices[$i], "check ref_ortho2 for slices[$i]" );
   }

   ################
   # TESTS 16-20: #
   ################
   # Get Robinson reference data:
   my @ref_robin_slices = get_ref_robin_slices();

   # Check Robinson map against reference:
   my $robin = $map->map( t_proj_robin( ellps => 'WGS84', over => 1 ), $map_size );
   foreach my $i ( 0 .. $#slices )
   {
      my $str = $slices[$i];
      my $slice = $robin->slice($str);
      is( "$slice", $ref_robin_slices[$i], "check ref_robin for slices[$i]" );
   }

}

done_testing;

sub get_ref_robin_slices {
    my @slices = ();
    push(@slices, <<"END");

[
 [43 43 43 43 43 43 43 43 43 43]
 [44 44 44 44 44 44 44 44 44 44]
 [44 44 44 44 44 44 44 44 44 44]
 [45 45 45 45 45 45 45 45 45 45]
 [45 45 45 45 45 45 45 45 45 45]
 [46 46 46 46 46 46 46 46 46 46]
 [46 46 46 46 46 46 46 46 46 46]
 [47 47 47 47 47 47 47 47 47 47]
 [47 47 47 47 47 47 47 47 47 47]
 [48 48 48 48 48 48 48 48 48 48]
]
END
    push(@slices, <<"END");

[
 [138 138 138 138 138 138 138 138 138 138]
 [138 138 138 138 138 138 138 138 138 138]
 [139 139 139 139 139 139 139 139 139 139]
 [139 139 139 139 139 139 139 139 139 139]
 [140 140 140 140 140 140 140 140 140 140]
 [140 140 140 140 140 140 140 140 140 140]
 [141 141 141 141 141 141 141 141 141 141]
 [141 141 141 141 141 141 141 141 141 141]
 [141 141 141 141 141 141 141 141 141 141]
 [142 142 142 142 142 142 142 142 142 142]
]
END
    push(@slices, <<"END");

[
 [133 133 133 133 133 133 133 133 133 133]
 [134 134 134 134 134 134 134 134 134 134]
 [134 134 134 134 134 134 134 134 134 134]
 [135 135 135 135 135 135 135 135 135 135]
 [135 135 135 135 135 135 135 135 135 135]
 [136 136 136 136 136 136 136 136 136 136]
 [136 136 136 136 136 136 136 136 136 136]
 [136 136 136 136 136 136 136 136 136 136]
 [137 137 137 137 137 137 137 137 137 137]
 [137 137 137 137 137 137 137 137 137 137]
]
END
    push(@slices, <<"END");

[
 [125 125 125 125 125 125 125 125 125 125]
 [126 126 126 126 126 126 126 126 126 126]
 [126 126 126 126 126 126 126 126 126 126]
 [127 127 127 127 127 127 127 127 127 127]
 [127 127 127 127 127 127 127 127 127 127]
 [128 128 128 128 128 128 128 128 128 128]
 [128 128 128 128 128 128 128 128 128 128]
 [129 129 129 129 129 129 129 129 129 129]
 [129 129 129 129 129 129 129 129 129 129]
 [130 130 130 130 130 130 130 130 130 130]
]
END
    push(@slices, <<"END");

[
 [229 229 229 229 229 229 229 229 229 229]
 [230 230 230 230 230 230 230 230 230 230]
 [230 230 230 230 230 230 230 230 230 230]
 [231 231 231 231 231 231 231 231 231 231]
 [231 231 231 231 231 231 231 231 231 231]
 [232 232 232 232 232 232 232 232 232 232]
 [232 232 232 232 232 232 232 232 232 232]
 [233 233 233 233 233 233 233 233 233 233]
 [234 234 234 234 234 234 234 234 234 234]
 [234 234 234 234 234 234 234 234 234 234]
]
END
    return @slices;
}

sub get_ref_ortho_slices {
    my @slices = ();
    push(@slices, <<"END");

[
 [118 118 118 118 118 118 118 118 118 118]
 [119 119 119 119 119 119 119 119 119 119]
 [119 119 119 119 119 119 119 119 119 119]
 [120 120 120 120 120 120 120 120 120 120]
 [120 120 120 120 120 120 120 120 120 120]
 [121 121 121 121 121 121 121 121 121 121]
 [121 121 121 121 121 121 121 121 121 121]
 [121 121 121 121 121 121 121 121 121 121]
 [122 122 122 122 122 122 122 122 122 122]
 [122 122 122 122 122 122 122 122 122 122]
]
END
    push(@slices, <<"END");

[
 [183 183 183 183 183 184 184 184 184 184]
 [183 183 183 184 184 184 184 184 184 184]
 [183 184 184 184 184 184 184 184 185 185]
 [184 184 184 184 184 184 185 185 185 185]
 [184 184 184 184 185 185 185 185 185 185]
 [184 184 185 185 185 185 185 185 185 186]
 [185 185 185 185 185 185 185 186 186 186]
 [185 185 185 185 185 186 186 186 186 186]
 [185 185 185 186 186 186 186 186 186 186]
 [185 186 186 186 186 186 186 186 187 187]
]
END
    push(@slices, <<"END");

[
 [188 188 188 188 188 188 188 188 188 188]
 [189 189 189 189 189 189 189 189 189 189]
 [189 189 189 189 189 189 189 189 189 189]
 [189 189 189 189 189 189 189 189 189 189]
 [190 190 190 190 190 190 190 190 190 190]
 [190 190 190 190 190 190 190 190 190 190]
 [190 190 190 190 190 190 190 190 190 190]
 [191 191 191 191 191 191 191 191 191 191]
 [191 191 191 191 191 191 191 191 191 191]
 [191 191 191 191 191 191 191 191 191 191]
]
END
    push(@slices, <<"END");

[
 [172 172 172 171 171 171 171 171 170 170]
 [172 172 172 172 171 171 171 171 171 171]
 [172 172 172 172 172 172 171 171 171 171]
 [173 173 172 172 172 172 172 172 171 171]
 [173 173 173 173 172 172 172 172 172 171]
 [173 173 173 173 173 172 172 172 172 172]
 [174 173 173 173 173 173 173 172 172 172]
 [174 174 174 173 173 173 173 173 173 172]
 [174 174 174 174 174 173 173 173 173 173]
 [175 174 174 174 174 174 173 173 173 173]
]
END
    push(@slices, <<"END");

[
 [240 240 240 240 240 239 239 239 239 238]
 [240 240 239 239 239 239 239 238 238 238]
 [239 239 239 239 238 238 238 238 238 237]
 [239 238 238 238 238 238 237 237 237 237]
 [238 238 238 237 237 237 237 237 236 236]
 [237 237 237 237 237 236 236 236 236 236]
 [237 237 236 236 236 236 236 235 235 235]
 [236 236 236 236 235 235 235 235 234 234]
 [235 235 235 235 235 234 234 234 234 234]
 [235 235 234 234 234 234 234 233 233 233]
]
END
    return @slices;
}

sub get_ref_eqc_slices {
    my @slices = ();
    push(@slices, <<"END");

[
 [35 35 35 35 35 35 35 35 35 35]
 [35 35 35 35 35 35 35 35 35 35]
 [36 36 36 36 36 36 36 36 36 36]
 [36 36 36 36 36 36 36 36 36 36]
 [37 37 37 37 37 37 37 37 37 37]
 [37 37 37 37 37 37 37 37 37 37]
 [38 38 38 38 38 38 38 38 38 38]
 [38 38 38 38 38 38 38 38 38 38]
 [39 39 39 39 39 39 39 39 39 39]
 [39 39 39 39 39 39 39 39 39 39]
]
END
    push(@slices, <<"END");

[
 [139 139 139 139 139 139 139 139 139 139]
 [140 140 140 140 140 140 140 140 140 140]
 [140 140 140 140 140 140 140 140 140 140]
 [141 141 141 141 141 141 141 141 141 141]
 [141 141 141 141 141 141 141 141 141 141]
 [142 142 142 142 142 142 142 142 142 142]
 [142 142 142 142 142 142 142 142 142 142]
 [143 143 143 143 143 143 143 143 143 143]
 [143 143 143 143 143 143 143 143 143 143]
 [144 144 144 144 144 144 144 144 144 144]
]
END
    push(@slices, <<"END");

[
 [134 134 134 134 134 134 134 134 134 134]
 [134 134 134 134 134 134 134 134 134 134]
 [135 135 135 135 135 135 135 135 135 135]
 [135 135 135 135 135 135 135 135 135 135]
 [136 136 136 136 136 136 136 136 136 136]
 [136 136 136 136 136 136 136 136 136 136]
 [137 137 137 137 137 137 137 137 137 137]
 [137 137 137 137 137 137 137 137 137 137]
 [138 138 138 138 138 138 138 138 138 138]
 [139 139 139 139 139 139 139 139 139 139]
]
END
    push(@slices, <<"END");

[
 [125 125 125 125 125 125 125 125 125 125]
 [126 126 126 126 126 126 126 126 126 126]
 [126 126 126 126 126 126 126 126 126 126]
 [127 127 127 127 127 127 127 127 127 127]
 [127 127 127 127 127 127 127 127 127 127]
 [128 128 128 128 128 128 128 128 128 128]
 [128 128 128 128 128 128 128 128 128 128]
 [129 129 129 129 129 129 129 129 129 129]
 [129 129 129 129 129 129 129 129 129 129]
 [130 130 130 130 130 130 130 130 130 130]
]
END
    push(@slices, <<"END");

[
 [237 237 237 237 237 237 237 237 237 237]
 [238 238 238 238 238 238 238 238 238 238]
 [238 238 238 238 238 238 238 238 238 238]
 [239 239 239 239 239 239 239 239 239 239]
 [239 239 239 239 239 239 239 239 239 239]
 [240 240 240 240 240 240 240 240 240 240]
 [240 240 240 240 240 240 240 240 240 240]
 [241 241 241 241 241 241 241 241 241 241]
 [241 241 241 241 241 241 241 241 241 241]
 [242 242 242 242 242 242 242 242 242 242]
]
END
    return @slices;
}
