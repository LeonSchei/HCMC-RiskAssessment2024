library(RSQLite)
library(sf)
library(dplyr)
library(raster)
library(readxl)
library(data.table)


path = "<Project Folder>"

#Input exposure data
expo = sf::read_sf(paste0(path,"exposure//Res_exposure.shp"))

#Input hazard data
#Create Raster stack
rastlist <- list.files(path = paste0(path,"inundation_data//"), pattern='.tif$', 
                       all.files=TRUE, full.names=FALSE)


#import all raster files in folder using lapply
allrasters <- lapply(rastlist, raster)
#Stack all rasters
rasStack = stack(allrasters)
rasStack_proj = projectRaster(rasStack,crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
inun_tile = cbind(expo,raster::extract(rasStack_proj,expo[,'geometry'],fun = mean,na.rm = TRUE))
inun_tile[is.na(inun_tile)] = 0
colnames(inun_tile)[c(2:3)] = c("no_build_r","sum_struc_r")
colnames(inun_tile)[4:23] = paste0("X",1:20)

#Discretize water depth to align with the Bayesian Network
discr_depth = function(x){
  return(cut(x*100,breaks = c(1,11,21,31,55,220),include.lowest = TRUE,right = FALSE))
}

disc_wd = inun_tile %>% mutate_at(vars(contains('X')),discr_depth)

# #Get flood experience

#Compute f_events from flood history of HCMC (till 2013)
flood_st = read_excel(paste0(path,"flood_events//EPT_FloodedStreets_2010-2013.xlsx"),sheet = 'Sheet1')
flood_st[,-1] = mutate_all(flood_st[,-1], function(x) as.numeric(as.character(x)))
flood_st[,-1] = replace(flood_st[,-1], is.na(flood_st[,-1])==FALSE, 1)
flood_st[,-1] = replace(flood_st[,-1], is.na(flood_st[,-1]), 0)
flood_st$tot_events = rowSums(flood_st[,-1])
#Group by district
flood_dist_1 = flood_st %>% group_by(District) %>% summarise(f_events = sum(tot_events))
flood_dist_1 = flood_dist_1[-which(is.na(flood_dist_1$District)),]

#Compute f_events from flood history of HCMC (2015 - 2020)
flood_new = read_excel(paste0(path,"flood_events//EPT_FloodedStreets_2010-2013.xlsx"),sheet = 'Sheet2')
flood_new$f_events2 = rowSums(flood_new[,-1],na.rm = TRUE)
flood_dist_2 = flood_new[c('District','f_events2')]

all_years = merge(flood_dist_1,flood_dist_2,by = 'District',all = FALSE)
all_years$fe = (all_years$f_events + all_years$f_events2)/10

year_1 = flood_dist_1[-which(flood_dist_1$District %in% flood_dist_2$District),]
year_1$fe = (year_1$f_events)/4

year_2 = flood_dist_2[-which(flood_dist_2$District %in% flood_dist_1$District),]
year_2$fe = (year_2$f_events2)/6

flood_dist = rbind(all_years[c('District','fe')], year_1[c('District','fe')], year_2[c('District','fe')])

#Input district map
dist_map = st_read(paste0(path,"exposure//gadm41_VNM_2.shp"))
dist_map = dist_map[(dist_map$NAME_1=="Hồ Chí Minh"),c('NAME_2','VARNAME_2','ENGTYPE_2','geometry')]

flood_dist$District[which(flood_dist$District == "1")] = "Quận 1"
flood_dist$District[which(flood_dist$District == "2")] = "Quận 2"
flood_dist$District[which(flood_dist$District == "3")] = "Quận 3"
flood_dist$District[which(flood_dist$District == "4")] = "Quận 4"
flood_dist$District[which(flood_dist$District == "5")] = "Quận 5"
flood_dist$District[which(flood_dist$District == "6")] = "Quận 6"
flood_dist$District[which(flood_dist$District == "7")] = "Quận 7"
flood_dist$District[which(flood_dist$District == "8")] = "Quận 8"
flood_dist$District[which(flood_dist$District == "9")] = "Quận 9"
flood_dist$District[which(flood_dist$District == "10")]= "Quận 10"
flood_dist$District[which(flood_dist$District == "11")]= "Quận 11"
flood_dist$District[which(flood_dist$District == "12")]= "Quận 12"
flood_dist$District[which(flood_dist$District == "Nhà bè")]= "Nhà Bè"

flood_attr = merge(dist_map,flood_dist,by.x = 'NAME_2',by.y='District',all.x = TRUE)

data_disc = st_join(disc_wd,flood_attr,join = st_nearest_feature,left=TRUE)

#Discretize f_events according to the Bayesian Network loss model requirements
data_disc$fe = as.character(cut(data_disc$fe,breaks = c(0,0.5,1,2,5,10,max(na.omit(data_disc$fe))),include.lowest = TRUE,right = FALSE,labels = c('1','2','3','4','5','6')))

#Make unknown inputs (when were the houses last renovated and duration of the flood) as NA
data_disc$renov = "NA"
data_disc$dur = "NA"

#Make unknown flood experience NA (we dont have data from district 3, 10 and Can Gio)
data_disc$fe[is.na(data_disc$fe)] = "NA" 

#Make data into long table to merge with loss model lookup (Rafiezadeh Shahi et al. 2024)
library(tidyr)
data_lng = as.data.frame(pivot_longer(as.data.frame(data_disc), -colnames(as.data.frame(data_disc))[grepl("X",colnames(as.data.frame(data_disc)))==FALSE], values_to = "wd", names_to = "Scenario"))
data_lng$elev = 0
levels(data_lng$wd) = c(levels(data_lng$wd),'0')
data_lng$wd[is.na(data_lng$wd)] = 0
data_lng$wd = as.character(data_lng$wd)

#Lookup Model
lookup = read.csv(paste0(path,"look_up//LossModel_lookup_table.csv"),sep = ',')
lookup = replace(lookup, is.na(lookup), "NA")
lookup = separate(data = lookup, col = loss_interval, into = c("loss_lower", "loss_upper"), sep = "-")
lookup$loss_upper[is.na(lookup$loss_upper) & lookup$loss_lower == "0"] = "0"
lookup$wd <- gsub('-',',',lookup$wd)
lookup$loss_lower <- gsub("[()]",'',lookup$loss_lower)
lookup$loss_upper <- gsub('[()]','',lookup$loss_upper)
lookup$loss_lower <- gsub("\\[|\\]",'',lookup$loss_lower)
lookup$loss_upper <- gsub("\\[|\\]",'',lookup$loss_upper)

loss_1 = merge(as.data.frame(data_lng),lookup,by=c('wd','dur','elev','renov','fe'),all.x = TRUE)

loss_1[which(loss_1$wd=="0"),c("loss_lower","loss_upper","loss_avg")] = 0
loss_1[which(loss_1$wd=="0"),c("prob")] = 1

#Expected loss
loss_1$exp_loss = loss_1$loss_avg*loss_1$prob
loss_1$low_loss = as.numeric(loss_1$loss_lower)*loss_1$prob
loss_1$up_loss = as.numeric(loss_1$loss_upper)*loss_1$prob

exp_loss_1 = st_as_sf(loss_1 %>% group_by(Scenario, geometry,fe,sum_struc_r,wd,dur,elev,renov,quadkey) %>% summarize(b_exp = sum(exp_loss),
                                                                                                                     b_low = sum(low_loss),
                                                                                                                     b_high = sum(up_loss)))


#Summarize by quadkey
exp_loss_quad = st_drop_geometry(exp_loss_1) %>% group_by(Scenario, quadkey) %>% summarise(q_num = n(),
                                                                                           q_strc = sum(sum_struc_r),
                                                                                           q_b_exp = mean(b_exp),
                                                                                           q_b_low = mean(b_low),
                                                                                           q_b_high = mean(b_high))


#Merge with exposure
merge_tile = merge(expo,exp_loss_quad,by='quadkey',all = TRUE)

merge_tile[c('abs_low','abs_exp','abs_high')] = st_drop_geometry(merge_tile[c('q_b_low','q_b_exp','q_b_high')]) * merge_tile$q_strc

#Round the values to 3 significant digits
merge_tile[c('abs_low','abs_exp','abs_high','q_b_low','q_b_exp','q_b_high')] = round(st_drop_geometry(merge_tile[c('abs_low','abs_exp','abs_high','q_b_low','q_b_exp','q_b_high')]),3)

colnames(merge_tile)[7:9] = c('b_exp','b_low','b_high')

#Export the scenarios as shapefiles
setwd(paste0(path,"loss_output//"))
sc = paste0("X",1:20)
sc_file = gsub(".tif",'',rastlist)
for(i in 1:length(sc)){
  st_write(merge_tile[which(merge_tile$Scenario==sc[i]),c("quadkey", "Scenario","b_exp","b_low","b_high","geometry","abs_low","abs_exp","abs_high","agg_number","agg_struct")], paste0(sc_file[i],".shp"))
}
