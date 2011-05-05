execute("ntpdate-debian"){ action :nothing }
package("ntpdate"){ notifies :run, "execute[ntpdate-debian]" }
