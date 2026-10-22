require "ISUI/ISCollapsableWindow"
require "ISUI/ISTabPanel"
require "ISUI/ISRichTextPanel"
local Model=require "KFM/ExamModel"
local W=ISCollapsableWindow:derive("KFM_ExamWindow")
function W:createChildren()
 ISCollapsableWindow.createChildren(self)
 local top=self:titleBarHeight()
 self.tabs=ISTabPanel:new(0,top,self.width,self.height-top-self:resizeWidgetHeight())
 self.tabs:setAnchorRight(true);self.tabs:setAnchorBottom(true);self.tabs:setEqualTabWidth(false)
 self:addChild(self.tabs)
 self.pages={}
 for _,tab in ipairs(self.model.tabs)do
  local page=ISRichTextPanel:new(0,0,self.tabs.width,self.tabs.height-self.tabs.tabHeight)
  page:setAnchorRight(true);page:setAnchorBottom(true)
  page:initialise();page.background=false;page.clip=true;page.autosetheight=false
  page.marginLeft=14;page.marginRight=18
  page.text=tab.text;page:addScrollBars()
  self.tabs:addView(tab.label,page);page:paginate()
  self.pages[#self.pages+1]=page
 end
end
function W:onResize()
 if ISCollapsableWindow.onResize then ISCollapsableWindow.onResize(self) end
 if self.pages then for _,page in ipairs(self.pages)do page:paginate();page:updateScrollbars()end end
end
function W:new(x,y,width,height,model)
 local o=ISCollapsableWindow.new(self,x,y,width,height)
 o.model=model;o:setTitle(model.title);o.resizable=true;o.minimumWidth=380;o.minimumHeight=260
 return o
end
function W.show(payload)
 local model=Model.build(payload,getText,KFM.Client.partDisplayName)
 local core=getCore();local width=math.min(760,core:getScreenWidth()-30);local height=math.min(620,core:getScreenHeight()-40)
 local window=W:new((core:getScreenWidth()-width)/2,(core:getScreenHeight()-height)/2,width,height,model)
 window:initialise();window:addToUIManager()
 return window
end
return W
