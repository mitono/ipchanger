# ipchanger.tcl
# version 01.00.00
source combobox.tcl
package require combobox 2.3
catch {namespace import combobox::*}
set FONT {{MS Gothic} 9 normal}

set ::ip ""
set ::mask ""
set ::gw ""
set ::dns ""
set ::desc ""
set ::settings ""

proc gettime {} {
  clock format [clock seconds] -format {%Y/%m/%d %H:%M:%S}
}
 
proc putlog {str args} {
  .flog.text configure -state normal
  .flog.text insert end "\n[gettime] [string trimright $str "\n"]"
  .flog.text configure -state disabled
  .flog.text yview moveto 1
}

proc refresh_ipconfig {} {
  .frp.t1 configure -state normal
  .frp.t1 delete 1.0 end
  set filename ipconfig.txt
  exec ipconfig > $filename
  set widest 0

  set f [open $filename]
  while {[gets $f line] >= 0} {
    .frp.t1 insert end "$line\n"
    if {[set length [string bytelength $line] ] > $widest} {
	    set widest $length
	}
  }
  close $f
#  .frp.t1 configure -width $widest
  putlog "ipconfig結果を再取得して表示しました"
  .frp.t1 configure -state disabled
}

proc refresh_routeprint {} {
  .frp.t1 configure -state normal
  .frp.t1 delete 1.0 end
  set filename ipconfig.txt
  exec routeprint.bat > $filename
  set widest 0

  set f [open $filename]
  while {[gets $f line] >= 0} {
    .frp.t1 insert end "$line\n"
    if {[set length [string bytelength $line]] > $widest} {
	    set widest $length
	}
  }
  close $f
#  .frp.t1 configure -width $widest
  putlog "route print結果を再取得して表示しました"
  .frp.t1 configure -state disabled
}

proc refresh_target {w args} {
  .flp.1.fset.combo list delete 0 end
  set ::ip ""
  set ::mask ""
  set ::gw ""
  set ::dns ""
  set ::desc ""
  set ::settings ""
  set setting_names ""
  set f [open ./data/$::target]
  while {[gets $f line] >= 0} {
    lappend ::settings "$line"
  }
  close $f

  foreach line $::settings {
    if { [string index $line 0 ] == "\[" } {
      if { [string index $line end ] == "\]" } {
        lappend setting_names "$line"
      }
    }
  }

  foreach line [lsort $setting_names] {
    .flp.1.fset.combo list insert end [ string trimleft [ string trimright $line \] ] \[ ]
  }

  putlog "\"$::target\"の設定ファイルを読み込みました"
  .flp.1.fset.combo select 0
}

proc clear_setting_values {} {
  .flp.1.fip.text delete 1.0 end
  .flp.1.fmask.text delete 1.0 end
  .flp.1.fgw.text delete 1.0 end
  .flp.1.fdns.text delete 1.0 end
  .flp.2.fdesc.text delete 1.0 end
}

proc refresh_setting {w args} {
  clear_setting_values
  set in false
  foreach line $::settings {
    if { $in == true } {
	  set str [string range $line 0 [ expr [string first "=" $line ] - 1 ] ]
	  switch $str {
        ip      { set ::ip [ string trimleft $line "ip=" ]
                  .flp.1.fip.text insert end $::ip
				}
        mask    { set ::mask [ string trimleft $line "mask=" ]
                  .flp.1.fmask.text insert end $::mask
				}
        gw      { set ::gw [ string trimleft $line "gw=" ]
                  .flp.1.fgw.text insert end $::gw
				}
        dns     { set ::dns [ string trimleft $line "dns=" ]
                  .flp.1.fdns.text insert end $::dns
				}
        desc    { set ::desc [ string trimleft $line "desc=" ]
                  .flp.2.fdesc.text insert end $::desc
				}
	  }
    }
    if { [string index $line 0 ] == "\[" } {
      set in false
      if { [string index $line end ] == "\]" } {
        if { [ string trimleft [ string trimright $line \] ] \[ ] == $::setting_name } {
          set in true
        }
      }
    }
  }
  putlog "\"$::setting_name\"の設定を選択しました"
}

proc delete_setting {} {
  set answer [ tk_messageBox -type yesno -icon question -title "削除確認" -message "設定名称：$::setting_name\n本当に削除しても良いですか？" ]
  switch -- $answer {
   yes { putlog "削除しました" }
 }
}

proc save_setting {} {
  set in false
  set sstart 0
  set send 0
  set setting ""
  

  set i 0
  foreach line $::settings {
    set i [expr $i + 1]
    if { [string index $line 0 ] == "\[" } {
      if { $sstart > $send } {
	    set send $i
	  }
      if { [string index $line end ] == "\]" } {
        if { [ string trimleft [ string trimright $line \] ] \[ ] == $::setting_name } {
          set sstart $i
        }
      }
    }
  }
  if { $sstart > $send } {
    set send [expr $sstart + 10 ]
  }
  append rp_ip "ip=" [string trimright [.flp.1.fip.text get 1.0 end] "\n"]
  append rp_mask "mask=" [string trimright [.flp.1.fmask.text get 1.0 end] "\n"]
  append rp_gw "gw=" [string trimright [.flp.1.fgw.text get 1.0 end] "\n"]
  append rp_dns "dns=" [string trimright [.flp.1.fdns.text get 1.0 end] "\n"]
  append rp_desc "desc=" [string trimright [.flp.2.fdesc.text get 1.0 end] "\n"]
  set ::settings [lreplace $::settings $sstart [expr $send - 2] $rp_ip $rp_mask $rp_gw $rp_dns $rp_desc]
  set f [open ./data/$::target w]
  foreach line $::settings {
    puts $f $line
  }
  close $f
  putlog "\"$::setting_name\"の設定を書き込みました"
}

proc setToNic {} {
  set filename netsh.result
  putlog "以下のコマンドを実行します"
  putlog "netsh interface ipv4 set address \"$::target\" static \
          [string trimright [.flp.1.fip.text get 1.0 end] "\n"] \
		  [string trimright [.flp.1.fmask.text get 1.0 end] "\n"] \
		  [string trimright [.flp.1.fgw.text get 1.0 end] "\n"] \> $filename"
  exec netsh interface ipv4 set address "$::target" static \
          [string trimright [.flp.1.fip.text get 1.0 end] "\n"] \
		  [string trimright [.flp.1.fmask.text get 1.0 end] "\n"] \
		  [string trimright [.flp.1.fgw.text get 1.0 end] "\n"] > $filename
  refresh_ipconfig
}



frame .flp
frame .flp.1
frame .flp.1.ftg
frame .flp.1.fset
frame .flp.1.fgo
frame .flp.1.fip
frame .flp.1.fmask
frame .flp.1.fgw
frame .flp.1.fdns
frame .flp.2
frame .flp.2.fdesc
frame .flp.3
frame .flp.3.fbtns

frame .frp
frame .frp.fbt

frame .flog
text  .flog.text -font $FONT -bd 0 -height 2 -bg SystemButtonFace -highlightbackground gray -highlightcolor gray -highlightthickness 1

label .flp.1.ftg.famLabel -text "対象NIC:"
combobox .flp.1.ftg.famCombo \
	    -borderwidth 2 \
	    -width 30 \
		-font $FONT \
	    -textvariable target \
	    -editable false \
	    -highlightthickness 1 \
	    -command [list refresh_target] -borderwidth 0 -selectborderwidth 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
label .flp.1.fset.label -text "設定名称:"
combobox .flp.1.fset.combo \
	    -borderwidth 2 \
	    -width 30 \
		-font $FONT \
	    -textvariable setting_name \
	    -editable true \
	    -highlightthickness 1 \
	    -command [list refresh_setting] -borderwidth 0 -selectborderwidth 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
button .flp.1.fgo.bgo -text ">>>>>>>>>>\nこの設定を\nNICに反映\n>>>>>>>>>>" -font $FONT -command setToNic
label .flp.1.fip.label -text "IPアドレス:" -font $FONT
text  .flp.1.fip.text -font $FONT -height 1 -width 15 -bd 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
label .flp.1.fmask.label -text "サブネットマスク:" -font $FONT
text  .flp.1.fmask.text -font $FONT -height 1 -width 15 -bd 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
label .flp.1.fgw.label -text "ゲートウェイ:" -font $FONT
text  .flp.1.fgw.text -font $FONT -height 1 -width 15 -bd 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
label .flp.1.fdns.label -text "DNS:" -font $FONT
text  .flp.1.fdns.text -font $FONT -height 1 -width 15 -bd 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
label .flp.2.fdesc.label -text "説明:" -font $FONT
text  .flp.2.fdesc.text -font $FONT -height 5 -width 40 -bd 0 -highlightcolor gray -highlightbackground gray -highlightthickness 1
button .flp.3.fbtns.bdelete -text "削除" -font $FONT -command delete_setting
button .flp.3.fbtns.bnew -text "クリアして新規作成" -font $FONT -command exit
button .flp.3.fbtns.bsave -text "保存" -font $FONT -command save_setting

button .frp.fbt.bq -text "Quit" -font $FONT -command exit
frame  .frp.fbt.ffunc
button .frp.fbt.ffunc.b1 -text "ipcofig" -font $FONT -command refresh_ipconfig
button .frp.fbt.ffunc.broute -text "route print -4" -font $FONT -command refresh_routeprint
text  .frp.t1 -font $FONT -bd 0 -height 40 -width 100 -bg SystemButtonFace -highlightcolor gray -highlightbackground gray -highlightthickness 1


pack .flog -side bottom -fill x
pack .flog.text -side top -fill x

pack .flp -side left -fill y
pack .flp.1 -side top -fill x
pack .flp.1.ftg -side top -fill x
pack .flp.1.ftg.famLabel -side left
pack .flp.1.ftg.famCombo -side right
pack .flp.1.fset -side top -fill x
pack .flp.1.fset.label -side left
pack .flp.1.fset.combo -side right
pack .flp.1.fgo -side right -fill both -pady 10
pack .flp.1.fgo.bgo -side top
pack .flp.1.fip -side top -fill x
pack .flp.1.fip.label -side left
pack .flp.1.fip.text -side right
pack .flp.1.fmask -side top -fill x
pack .flp.1.fmask.label -side left
pack .flp.1.fmask.text -side right
pack .flp.1.fgw -side top -fill x
pack .flp.1.fgw.label -side left
pack .flp.1.fgw.text -side right
pack .flp.1.fdns -side top -fill x
pack .flp.1.fdns.label -side left
pack .flp.1.fdns.text -side right
pack .flp.2 -side top -fill x
pack .flp.2.fdesc -side top -fill x
pack .flp.2.fdesc.label -side left
pack .flp.2.fdesc.text -side right
pack .flp.3 -side top -fill x
pack .flp.3.fbtns -side top -fill x
grid .flp.3.fbtns.bdelete .flp.3.fbtns.bnew .flp.3.fbtns.bsave


pack .frp -side right -fill both -expand 1
pack .frp.fbt -side top -fill x
pack .frp.fbt.bq -side right
pack .frp.fbt.ffunc
grid .frp.fbt.ffunc.b1 .frp.fbt.ffunc.broute 
pack .frp.t1 -fill both -expand 1


refresh_ipconfig
cd data
foreach x [glob -types f *] {
  .flp.1.ftg.famCombo list insert end $x
}
cd ..
.flp.1.ftg.famCombo select 0

