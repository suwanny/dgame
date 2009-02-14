module UsersHelper

  def UsersHelper.getAllianceId(strVal)
    @allyId = 0;
    strVal = strVal.to_s
    
    if strVal == "red"
      @allyId = 0;
    elsif strVal == "green"
      @allyId = 1;
    elsif strVal == "blue"
      @allyId = 2;
    end
    @allyId
  end

  def UsersHelper.getAllianceStr(id)
    strId = "RED"
    if id == 1
      strId = "GREEN"
    elsif id == 2
      strId = "BLUE"
    end
    strId
  end


end
