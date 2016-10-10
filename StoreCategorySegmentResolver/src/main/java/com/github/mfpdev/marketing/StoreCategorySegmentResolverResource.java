/**
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.github.mfpdev.marketing;

import com.google.gson.Gson;
import com.ibm.json.java.JSON;
import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;
import com.ibm.mfp.adapter.api.ConfigurationAPI;
import com.ibm.mfp.adapter.api.OAuthSecurity;
import com.jayway.jsonpath.Configuration;
import com.jayway.jsonpath.JsonPath;
import com.jayway.jsonpath.ReadContext;
import io.swagger.annotations.Api;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import javax.ws.rs.DefaultValue;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.HashSet;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Api(value = "Store category resolver adapter")
@Path("/")
public class StoreCategorySegmentResolverResource {
    private static final Gson gson = new Gson();
    private static final Logger logger = Logger.getLogger(ResolverAdapterData.class.getName());
    private static final String DEFAULT_SEGMENT = "default";
    private static int EARTH_RADIUS = 6371; // Radius of the earth in km

    @Context
    ConfigurationAPI configurationAPI;

    private CloseableHttpClient httpClient = HttpClients.createDefault();

    private ResponseHandler<String> responseHandler;

    {
        responseHandler = new ResponseHandler<String>() {
            @Override
            public String handleResponse(
                    final HttpResponse response) throws IOException {
                int status = response.getStatusLine().getStatusCode();
                if (status >= 200 && status < 300) {
                    HttpEntity entity = response.getEntity();
                    return entity != null ? EntityUtils.toString(entity) : null;
                } else {
                    throw new ClientProtocolException("Unexpected response status: " + status);
                }
            }
        };
    }

    @POST
    @Path("segment")
    @Produces("text/plain;charset=UTF-8")
    @OAuthSecurity(scope = "configuration-user-login")
    public String getSegment(String body) throws Exception {
        ResolverAdapterData data = gson.fromJson(body, ResolverAdapterData.class);

        // Get the authenticatedUser object
        if (data.getQueryArguments().containsKey("longitude") && data.getQueryArguments().containsKey("latitude")) {
            List<String> longitude = data.getQueryArguments().get("longitude");
            List<String> latitude = data.getQueryArguments().get("latitude");

            return getStoreCategory (Double.valueOf(longitude.get(0)), Double.valueOf(latitude.get(0)));
        }
        return DEFAULT_SEGMENT;
    }

    private String getStoreCategory (double longitude, double latitude) {
        String minDistCategory = DEFAULT_SEGMENT;
        boolean isIncludeUmbrellaDeal = false;

        try {
            InputStream stream = this.getClass().getResource("/json/stores.json").openStream();
            JSONObject storesJson = JSONObject.parse(new BufferedInputStream(stream));

            //initial min distance
            double minDist = Double.valueOf(configurationAPI.getPropertyValue("maxDistanceFromStoreInKM"));

            JSONArray storeLocations = (JSONArray) storesJson.get("stores-locations");
            for (Object store : storeLocations){
                JSONObject storeJson = (JSONObject)store;
                double lon = (Double) storeJson.get("longitude");
                double lat = (Double) storeJson.get("latitude");

                double dist = distance (longitude, latitude, lon, lat);
                if (dist < minDist) {
                    minDist = dist;
                    minDistCategory = (String) storeJson.get("category");
                    isIncludeUmbrellaDeal = (Boolean) storeJson.get("umbrellaDeal");
                }
            }

        } catch (Exception e) {
            logger.log(Level.WARNING, "Cannot load stores.json" + e.getMessage(), e);
        }

        if (isIncludeUmbrellaDeal && isRainy(longitude, latitude)) {
            return minDistCategory + "-rainy";
        } else {
            return minDistCategory;
        }

    }

    private double distance(double lon1, double lat1, double lon2, double lat2) {
        double dLat = Math.toRadians(lat2 - lat1);  // Javascript functions in radians
        double dLon = Math.toRadians(lon2-lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return EARTH_RADIUS * c; // Distance in km
    }

    private boolean isRainy(double longitude, double latitude) {

        String username = configurationAPI.getPropertyValue("twcserviceUsername");
        String password = configurationAPI.getPropertyValue("twcservicePassword");
        HttpGet httpRequest = new HttpGet("https://" + username + ":" + password + "@twcservice.mybluemix.net/api/weather/v1/geocode/" + latitude + "/" + longitude + "/observations.json");

        JSONObject json = getJSONObjectFromRequest(httpRequest);

        Long weatherCode = -1l;

        if (json != null && json.containsKey("observation")) {
            weatherCode = (Long) ((JSONObject) json.get("observation")).get("wx_icon");
        }
        //For all code see https://new-console.ng.bluemix.net/docs/services/Weather/weather_rest_apis.html#icon_code_images
        return (weatherCode > 2 && weatherCode < 13 ||
                weatherCode > 37 && weatherCode < 41 ||
                weatherCode == 35 ||
                weatherCode == 45 ||
                weatherCode == 47);
    }

    private JSONObject getJSONObjectFromRequest(HttpUriRequest request) {
        JSONObject jsonObject = null;
        try {
            String responseBody = httpClient.execute(request, responseHandler);
            jsonObject = JSONObject.parse(responseBody);
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Issue while trying to invoke a request " + request.getURI() + " " + e.getMessage(), e);
        }
        return jsonObject;
    }
}

