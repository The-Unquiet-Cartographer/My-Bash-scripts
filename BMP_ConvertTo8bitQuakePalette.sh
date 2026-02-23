#!/bin/bash

#USER VARS
	readonly newWidth_pixels=64				#Should handle any size
	readonly newHeight_pixels=64			#Should handle any size
	readonly convertedFilePrefix=""			#Will be prepended to the output filename
	readonly convertedFileSuffix="_new"		#Will be appended to the output filename
	#!Add a prefix or a suffix if you don't want to overwrite the old file!

	readonly rotation=0						#[0/90/180/270] Rotate the image by 90 degree increments.
	readonly mirror_x=false					#[true/false] Flip the image horizontally?
	readonly mirror_y=false					#[true/false] Flip the image vertically?
	readonly logging=false					#[true/false] Log operation?


#CONST
	readonly quakePalette=(
		"#000000" "#0f0f0f" "#1f1f1f" "#2f2f2f" "#3f3f3f" "#4b4b4b" "#5b5b5b" "#6b6b6b" "#7b7b7b" "#8b8b8b" "#9b9b9b" "#ababab" "#bbbbbb" "#cbcbcb" "#dbdbdb" "#ebebeb"
		"#0f0b07" "#170f0b" "#1f170b" "#271b0f" "#2f2313" "#372b17" "#3f2f17" "#4b371b" "#533b1b" "#5b431f" "#634b1f" "#6b531f" "#73571f" "#7b5f23" "#836723" "#8f6f23"
		"#0b0b0f" "#13131b" "#1b1b27" "#272733" "#2f2f3f" "#37374b" "#3f3f57" "#474767" "#4f4f73" "#5b5b7f" "#63638b" "#6b6b97" "#7373a3" "#7b7baf" "#8383bb" "#8b8bcb"
		"#000000" "#070700" "#0b0b00" "#131300" "#1b1b00" "#232300" "#2b2b07" "#2f2f07" "#373707" "#3f3f07" "#474707" "#4b4b0b" "#53530b" "#5b5b0b" "#63630b" "#6b6b0f"

		"#070000" "#0f0000" "#170000" "#1f0000" "#270000" "#2f0000" "#370000" "#3f0000" "#470000" "#4f0000" "#570000" "#5f0000" "#670000" "#6f0000" "#770000" "#7f0000"
		"#131300" "#1b1b00" "#232300" "#2f2b00" "#372f00" "#433700" "#4b3b07" "#574307" "#5f4707" "#6b4b0b" "#77530f" "#835713" "#8b5b13" "#975f1b" "#a3631f" "#af6723"
		"#231307" "#2f170b" "#3b1f0f" "#4b2313" "#572b17" "#632f1f" "#733723" "#7f3b2b"	"#8f4333" "#9f4f33" "#af632f" "#bf772f" "#cf8f2b" "#dfab27" "#efcb1f" "#fff31b"
		"#0b0700" "#1b1300" "#2b230f" "#372b13" "#47331b" "#533723" "#633f2b" "#6f4733"	"#7f533f" "#8b5f47" "#9b6b53" "#a77b5f" "#b7876b" "#c3937b" "#d3a38b" "#e3b397"

		"#ab8ba3" "#9f7f97" "#937387" "#8b677b" "#7f5b6f" "#775363" "#6b4b57" "#5f3f4b"	"#573743" "#4b2f37" "#43272f" "#371f23" "#2b171b" "#231313" "#170b0b" "#0f0707"
		"#bb739f" "#af6b8f" "#a35f83" "#975777" "#8b4f6b" "#7f4b5f" "#734353" "#6b3b4b"	"#5f333f" "#532b37" "#47232b" "#3b1f23" "#2f171b" "#231313" "#170b0b" "#0f0707"
		"#dbc3bb" "#cbb3a7" "#bfa39b" "#af978b" "#a3877b" "#977b6f" "#876f5f" "#7b6353"	"#6b5747" "#5f4b3b" "#533f33" "#433327" "#372b1f" "#271f17" "#1b130f" "#0f0b07"
		"#6f837b" "#677b6f" "#5f7367" "#576b5f" "#4f6357" "#475b4f" "#3f5347" "#374b3f"	"#2f4337" "#2b3b2f" "#233327" "#1f2b1f" "#172317" "#0f1b13" "#0b130b" "#070b07"

		"#fff31b" "#efdf17" "#dbcb13" "#cbb70f" "#bba70f" "#ab970b" "#9b8307" "#8b7307"	"#7b6307" "#6b5300" "#5b4700" "#4b3700" "#3b2b00" "#2b1f00" "#1b0f00" "#0b0700"
		"#0000ff" "#0b0bef" "#1313df" "#1b1bcf" "#2323bf" "#2b2baf" "#2f2f9f" "#2f2f8f"	"#2f2f7f" "#2f2f6f" "#2f2f5f" "#2b2b4f" "#23233f" "#1b1b2f" "#13131f" "#0b0b0f"
		"#2b0000" "#3b0000" "#4b0700" "#5f0700" "#6f0f00" "#7f1707" "#931f07" "#a3270b"	"#b7330f" "#c34b1b" "#cf632b" "#db7f3b" "#e3974f" "#e7ab5f" "#efbf77" "#f7d38b"
		"#a77b3b" "#b79b37" "#c7c337" "#e7e357" "#7fbfff" "#abe7ff" "#d7ffff" "#670000"	"#8b0000" "#b30000" "#d70000" "#ff0000" "#fff393" "#fff7c7" "#ffffff" "#9f5b53"
	)
	readonly paletteSize=${#quakePalette[@]}

#BMP output sizes
	readonly size_bytes_palette=$(( 256 * 4 ))
	readonly size_bytes_header=$(( 14 + 40 + size_bytes_palette ))
	readonly size_bytes_newRow=$(( ($newWidth_pixels + 3) & ~3 ))
	readonly size_bytes_image=$(( size_bytes_newRow * newHeight_pixels ))
	readonly size_bytes_file=$(( size_bytes_header + size_bytes_image ))


#Read an integer at a given offset (little-endian format, 2-byte & 4-byte variants)
	Read_LE_UInt16() {
		od -An -t u2 -j "$1" -N 2 "$arg_input" | tr -d ' '
	}
	Read_LE_UInt32() {
		od -An -t u4 -j "$1" -N 4 "$arg_input" | tr -d ' '
	}
	Write_LE_32() {
		printf "%08x" "$1" | sed 's/\(..\)/\1 /g' | awk '{print $4$3$2$1}' | xxd -r -p
	}
#Find the index of the closest Quake palette colour using RGB distance
	NearestIndex() {
		local input_r=$1
		local input_g=$2
		local input_b=$3
		local best_index=0
		local best_dist=999999999
		for ((i=0; i<paletteSize; i++)); do
			hex=${quakePalette[i]}
			palette_r=$((16#${hex:1:2}))
			palette_g=$((16#${hex:3:2}))
			palette_b=$((16#${hex:5:2}))
			distance_r=$((input_r - palette_r))
			distance_g=$((input_g - palette_g))
			distance_b=$((input_b - palette_b))
			dist=$((distance_r*distance_r + distance_g*distance_g + distance_b*distance_b))
			if [ $dist -lt $best_dist ]; then
				best_dist=$dist
				best_index=$i
			fi
		done
		echo "$best_index"
	}
# Detect and read BMP palette for indexed images
	sourceBMPPalette=()		#I would rather pass this as an argument but it was causing me gyp so I left it global.
	ReadBMPPalette() {
		sourceBMPPalette=()
		local _bitsPerPixel=$1
		local numColors=$((1 << _bitsPerPixel))
		for ((i=0;i<numColors;i++)); do
			offset=$((14 + 40 + i*4))   # BMP header + DIB header + palette entry
			b=$(od -An -t u1 -j $offset -N 1 "$arg_input" | tr -d ' ')
			g=$(od -An -t u1 -j $((offset+1)) -N 1 "$arg_input" | tr -d ' ')
			r=$(od -An -t u1 -j $((offset+2)) -N 1 "$arg_input" | tr -d ' ')
		#Fallback to 0 if empty
			r=${r:-0}
			g=${g:-0}
			b=${b:-0}
			sourceBMPPalette+=("$r,$g,$b")
		done
	#Logging the palette for debugging
		if [ $logging = true ]; then
			echo "Palette contents:"
			for color in "${sourceBMPPalette[@]}"; do
				echo "$color"
			done
		fi
	}


##################################################
#
#	WRITING TO OUTPUT
#
##################################################
# Loop over all BMPs in current folder
	for arg_input in *.bmp; do
		[[ -f "$arg_input" ]] || continue
	#Create a temporary file in the case that we're overwriting the old one
		if [ "$convertedFilePrefix" = "" ] && [ "$convertedFileSuffix" = "" ]; then
			arg_output="${arg_input%.bmp}_temp.bmp"
		else
			arg_output="${convertedFilePrefix}${arg_input%.bmp}${convertedFileSuffix}.bmp"
		fi
		echo "Converting $arg_input..."

   # Read BMP header info
		src_width_pixels=$(Read_LE_UInt32 18)
		src_height_pixels=$(Read_LE_UInt32 22)
		src_bitsPerPixel=$(Read_LE_UInt16 28)
		[ "$logging" = true ] && echo "Bits-per-pixel is $src_bitsPerPixel"
	# Read palette if needed
		if (( src_bitsPerPixel == 4 || src_bitsPerPixel == 8 )); then
			ReadBMPPalette $src_bitsPerPixel
		fi
		src_byteOffset_pixels=$(Read_LE_UInt32 10)
		src_bytesPerRow=$(( (src_width_pixels*src_bitsPerPixel/8 + 3) & ~3 ))




	#WRITE .BMP HEADER
		{
		#Signature
			printf "BM"
		#File size (little-endian)
			Write_LE_32 "$size_bytes_file"
		#Reserved
			printf "\x00\x00\x00\x00"
		#Pixel data offset
			Write_LE_32 "$size_bytes_header"
		#DIB header size (40 bytes)
			printf "\x28\x00\x00\x00"
		#Width / Height
			Write_LE_32 "$newWidth_pixels"
			Write_LE_32 "$newHeight_pixels"
		#Planes
			printf "\x01\x00"
		#Bits per pixel (8)
			printf "\x08\x00"
		#Compression (none)
			printf "\x00\x00\x00\x00"
		#Image size
			Write_LE_32 "$size_bytes_image"
		#Resolution (2835 pixels/meter ≈ 72 DPI)
			printf "\x13\x0B\x00\x00"
			printf "\x13\x0B\x00\x00"
		#Colors used (256)
			printf "\x00\x01\x00\x00"
		#Important colors
			printf "\x00\x01\x00\x00"
		} > "$arg_output"

		[ "$logging" = true ] && echo "Size after writing header: $(stat -c%s "$arg_output") bytes"


	#WRITE QUAKE PALETTE
		for ((i=0; i<256; i++)); do
			hex=${quakePalette[i]}
			r=$((16#${hex:1:2}))
			g=$((16#${hex:3:2}))
			b=$((16#${hex:5:2}))
		#BMP palette format: Blue Green Red 00
			printf "%02x%02x%02x00" "$b" "$g" "$r" | xxd -r -p >> "$arg_output"
		done

		[ "$logging" = true ] && echo "Size after writing palette:  $(stat -c%s "$arg_output") bytes"


	#CONVERT PIXEL DATA
		Relative_XPos_InSource() {
			local _new_xCoord=$1
			echo $(( _new_xCoord * src_width_pixels / newWidth_pixels ))
		}
		Relative_YPos_InSource() {
			local _new_yCoord=$1
			echo $(( _new_yCoord * src_height_pixels / newHeight_pixels ))
		}
	#Nearest-neighbor scaling loop
		for ((new_yCoord=0;new_yCoord<newHeight_pixels;new_yCoord++)); do
			for ((new_xCoord=0;new_xCoord<newWidth_pixels;new_xCoord++)); do
			#Get relative coordinate in the source image
			#If using rotation, apply rotation formula to get a modified coordinate
				src_xCoord=""
				src_yCoord=""
				case $rotation in
				90)
					src_xCoord=$(($src_height_pixels - 1 - $(Relative_YPos_InSource $new_yCoord)))
					src_yCoord=$(Relative_XPos_InSource $new_xCoord)
				;;
				180)
					src_xCoord=$(($src_width_pixels - 1 - $(Relative_XPos_InSource $new_xCoord)))
					src_yCoord=$(($src_height_pixels - 1 - $(Relative_YPos_InSource $new_yCoord)))
				;;
				270)
					src_xCoord=$(Relative_YPos_InSource $new_yCoord)
					src_yCoord=$(($src_width_pixels - 1 - $(Relative_XPos_InSource $new_xCoord)))
				;;
				*)
					src_yCoord=$(( new_yCoord * src_height_pixels / newHeight_pixels ))
					src_xCoord=$(( new_xCoord * src_width_pixels / newWidth_pixels ))
				;;
				esac
			#If using mirror operation, flip coordinate
				[ "$mirror_x" = true ] && src_xCoord=$(($src_width_pixels - 1 - $src_xCoord))
				[ "$mirror_y" = true ] && src_yCoord=$(($src_height_pixels - 1 - $src_yCoord))

			#RETRIEVE BYTE INDEX
				src_y_byteIndex0=$(( src_byteOffset_pixels + $src_yCoord * src_bytesPerRow ))
				src_x_byteIndex=""
				case $src_bitsPerPixel in
			#24-bit source; each pixel uses 3 bytes
				24)
					src_x_byteIndex=$(( src_y_byteIndex0 + $src_xCoord * 3 ))
					input_b=$(od -An -t u1 -j $src_x_byteIndex -N 1 "$arg_input" | tr -d ' ')
					input_g=$(od -An -t u1 -j $((src_x_byteIndex+1)) -N 1 "$arg_input" | tr -d ' ')
					input_r=$(od -An -t u1 -j $((src_x_byteIndex+2)) -N 1 "$arg_input" | tr -d ' ')
				;;
			#8-bit source; each pixel uses 1 byte
				8)
					src_x_byteIndex=$(( src_y_byteIndex0 + $src_xCoord ))
					index=$(od -An -t u1 -j $src_x_byteIndex -N 1 "$arg_input" | tr -d ' ')
					index=${index:-0}		#Fallback
					IFS=',' read input_r input_g input_b <<< "${sourceBMPPalette[index]}"
				;;
			#4-bit source; each pixel uses half a byte (so we get the byte and choose which half to read)
				4)
					src_x_byteIndex=$(( src_y_byteIndex0 + $src_xCoord / 2 ))
					byte=$(od -An -t u1 -j $src_x_byteIndex -N 1 "$arg_input" | tr -d ' ')
					byte=${byte:-0}		#Fallback
					if (( src_xCoord % 2 == 0 )); then
						index=$(( byte >> 4 ))
					else
						index=$(( byte & 0x0F ))
					fi
					index=$(( index < ${#sourceBMPPalette[@]} ? index : 0 ))		# bounds check
					IFS=',' read input_r input_g input_b <<< "${sourceBMPPalette[index]}"
				;;
				esac
				[ "$logging" = true ] && echo "Pixel @ ($new_xCoord, $new_yCoord); Reading source pixel @ ($src_xCoord, $src_yCoord), byte index $src_x_byteIndex."
			#Fallback in case anything is empty
				input_r=${input_r:-0}
				input_g=${input_g:-0}
				input_b=${input_b:-0}
				paletteIndex=$(NearestIndex $input_r $input_g $input_b)
				printf "%02x" "$paletteIndex" | xxd -r -p >> "$arg_output"
			done

		#Row padding
			padding=$(( size_bytes_newRow - newWidth_pixels ))
			for ((p=0;p<padding;p++)); do
				printf "\x00" >> "$arg_output"
			done
		done

	#Overwrite the old file if the name stays the same
		if [ "$convertedFilePrefix" = "" ] && [ "$convertedFileSuffix" = "" ]; then
			mv "$arg_output" "$arg_input"
		fi

		echo "Converted $arg_input -> $arg_output"

	done
