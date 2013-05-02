# To change this template, choose Tools | Templates
# and open the template in the editor.
require "watir"
require 'yaml'

## feixin global variable
$feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/);
$feinxin_frame = $feixin_browser.frame(:src,"content/freeSms.htm?tabIndex=0");

## cnfol global variable
$cnfolBrowser = Watir::Browser.attach(:url,"http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817");

# other
$sleep_time = 5; ## sleep time
$file_name = "huangjin.yaml";
$log_file = "log_file.txt";

# 发送短信息
def send_sms(message="")
  ## feixin variable
  $feinxin_frame.checkbox(:id,"sendToMe").set;
  $feinxin_frame.text_field(:id,"smsContent").set message;
  $feinxin_frame.link(:id,"submitBtn").click;

  sleep $sleep_time; ## 停止2s
end

# 获取直播内容
def get_live_content()
  #$cnfolBrowser.refresh();
  #sleep $sleep_time; ## 停止2s

  live_content = Hash.new;
  $cnfolBrowser.div(:id =>"livemsgContent").divs(:class=>"clearfix Uline").each do |div|
    live_content.store(div.i.text, div.span.text);
  end

  return live_content;
end

# 把Hash写入文件
def write_file(live_content,file_name=$file_name)
  File.open(file_name,"w") do|io|
    YAML.dump(live_content,io)
  end
end

def write_log(log)
  log_file = open($log_file,"a");
  log_file.puts(log);
end

# 读取文件，返回Hash
def read_file(file_name=$file_name)
  db_live_content = Hash.new;
  if (File.exist?(file_name))
    YAML.load_file(file_name).each do|i|
      key = i[0];
      value = i[1];
      db_live_content[key] = value;
    end
  end
  return db_live_content;
end

# 无限循环
while true do
  begin
    live_content = get_live_content(); ## 获取网页的直播内容
    db_live_content = read_file(); ## 获取存储的直播内容

    ## 对比live_content和db_live_content
    ## 遍历live_content，判断key是否存在于db_live_content
    smsContent=""; ## 记录这次扫描短信的所有内容
    live_content.each do |k,v|
      unless(db_live_content.has_key?(k))  # unless和if相反
        smsContent = smsContent+ ">>" + k + " " +v;
        send_sms(k + " " +v); ## 发送飞信
      end
    end

    # 将直播内容存储到文件中
    unless(live_content.empty?)
      write_file(live_content); # 存储文件
    end

    ## 写入日志
    log = "time: "+Time.now.to_s + " SMS content: "+smsContent;
    write_log(log);
    puts log;

    sleep $sleep_time; # 休眠几秒
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
end

