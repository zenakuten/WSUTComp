// ====================================================================
//  Class:  UT2K4UI.GUIGFXButton
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================

class wsGUICheckBoxButton extends GUICheckBoxButton;

#exec TEXTURE IMPORT NAME=checkBoxX_f GROUP=GUI FILE=Textures\checkBoxX_f.tga MIPS=off ALPHA=1 
#exec TEXTURE IMPORT NAME=checkBoxX_p GROUP=GUI FILE=Textures\checkBoxX_p.tga MIPS=off ALPHA=1 

defaultproperties
{
     CheckedOverlay(0)=Texture'2K4Menus.Controls.checkBoxX_b'
     CheckedOverlay(1)=Texture'2K4Menus.Controls.checkBoxX_w'
     CheckedOverlay(2)=Texture'WSUTComp.GUI.checkBoxX_f'
     CheckedOverlay(3)=Texture'WSUTComp.GUI.checkBoxX_p'
     CheckedOverlay(4)=Texture'2K4Menus.Controls.checkBoxX_d'

     StyleName="WSButton"
}
