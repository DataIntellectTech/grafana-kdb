# The Grafana-KDB Adaptor
Grafana is an open source analytics platform, used to display time-series data from a web application. Currently it supports a variety of data sources including Graphite, InfluxDb & Prometheus with users including the likes of Paypal, Ebay, Intel and Booking.com.  However, there is no in-built support for direct analysis of data from kdb+. Thus, using the SimpleJSON data source, we have engineered an adaptor to allow visualisation of kdb+ data.

## Requirments
Grafana v5.2.2+

Kdb v3.5+

## Getting Started

1. Download and set up Grafana. This is well explained on the [Grafana website](https://grafana.com/get), where you have the option to either download the software locally or let Grafana host it for you. For the purpose of this document, we host the software locally.

2. Download our adaptor jsonconv.q from this repository.

3. In your newly installed Grafana folder run the command:
    ```./bin/grafana-server web```.
This will start your Grafana server. If you would like to alter the port which this is run on, this can be changed in:
    ```/grafana-5.2.2/conf/custom.ini```.

4. You can now open the Grafana server in your web browser where you will be greeted with a login page to fill in appropriatly.

5. Once logged in, navigate to the plugin section where you will find the simple JSON adaptor, install this.

6. Upon installation of the JSON you can now set-up your datasource. 

7. Host your data on a port accesible to Grafana and in this port load our script jsonconv.q.

8. In the "add new datasource" panel, enter the details for the port in which your data is hosted, making the type SimpleJSON.

9. Run the test button on the bottom of your page, this should succeed and you are ready to go!

## Using the adaptor

With the adaptor successfully installed your data is ready to visualized. From this point onwards you can proceed to use Grafana as it is intended, with the only difference coming in the form of the queries. Use cases and further examples of the queries can be seen in our blogpost: ENTER LINK FOR BLOGPOST. Here you can see examples of graphs, tables, heatmaps and single statistics. 
The best explanation of the inputs allowed in the query section can be seen pictorially here:

![InputFormat](https://github.com/AquaQAnalytics/grafana-kdb/blob/Json/DropDownOptions.png?raw=true)

Upon opening the query box, in the metrics tab, the user will be provided with a populated drop down of all possible options. Due to the limitations of the JSON messages, it is not possible for our adaptor to distinguish between panels. Consequently, every possible option is returned for each panel, the user can reduce these choices by simply entering the first letter of their panel type, g for graph, t for table and o for other (heatmap or single stat). From here, you can follow the above diagram to specify your type of query. 

## Limitations
This adaptor has been built to allow visualisation of real-time non-partitioned data. It is capable of handling static and timeseries data. However, due to the nature of HDB data on disk, it cannot present such partioned data. A solution for this is currently being worked on. In addition, the drop-down options have been formed such that only one query is necessary. If more than one query on a specfic panel is made it will throw an error.
