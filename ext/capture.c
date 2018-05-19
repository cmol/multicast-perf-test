#include <pcap.h>
#include <stdio.h>

void DumpHex(const void* data, size_t size) {
  char ascii[17];
  size_t i, j;
  ascii[16] = '\0';
  for (i = 0; i < size; ++i) {
    printf("%02X ", ((unsigned char*)data)[i]);
    if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
      ascii[i % 16] = ((unsigned char*)data)[i];
    } else {
      ascii[i % 16] = '.';
    }
    if ((i+1) % 8 == 0 || i+1 == size) {
      printf(" ");
      if ((i+1) % 16 == 0) {
        printf("|  %s \n", ascii);
      } else if (i+1 == size) {
        ascii[(i+1) % 16] = '\0';
        if ((i+1) % 16 <= 8) {
          printf(" ");
        }
        for (j = (i+1) % 16; j < 16; ++j) {
          printf("   ");
        }
        printf("|  %s \n", ascii);
      }
    }
  }
}

int main(int argc, char *argv[])
{
  pcap_t *handle;     /* Session handle */
  char *dev;      /* The device to sniff on */
  char errbuf[PCAP_ERRBUF_SIZE];  /* Error string */
  struct bpf_program fp;    /* The compiled filter */
  //char filter_exp[] = "port 22";  /* The filter expression */
  char filter_exp[] = "ip6 multicast and udp port 5353";  /* The filter expression */
  bpf_u_int32 mask;   /* Our netmask */
  bpf_u_int32 net;    /* Our IP */
  struct pcap_pkthdr header;  /* The header that pcap gives us */
  const u_char *packet;   /* The actual packet */

  /* Define the device */
  dev = pcap_lookupdev(errbuf);
  if (dev == NULL) {
    fprintf(stderr, "Couldn't find default device: %s\n", errbuf);
    return(2);
  }
  /* Find the properties for the device */
  if (pcap_lookupnet(dev, &net, &mask, errbuf) == -1) {
    fprintf(stderr, "Couldn't get netmask for device %s: %s\n", dev, errbuf);
    net = 0;
    mask = 0;
  }
  /* Open the session in promiscuous mode */
  handle = pcap_open_live(dev, BUFSIZ, 1, 1000, errbuf);
  if (handle == NULL) {
    fprintf(stderr, "Couldn't open device %s: %s\n", dev, errbuf);
    return(2);
  }
  /* Compile and apply the filter */
  if (pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
    fprintf(stderr, "Couldn't parse filter %s: %s\n", filter_exp, pcap_geterr(handle));
    return(2);
  }
  if (pcap_setfilter(handle, &fp) == -1) {
    fprintf(stderr, "Couldn't install filter %s: %s\n", filter_exp, pcap_geterr(handle));
    return(2);
  }
  while(1) {
    /* Grab a packet */
    packet = pcap_next(handle, &header);
    /* Print its length */
    printf("Jacked a packet with length of [%d]\n", header.len);
    DumpHex(packet, header.len);
  }
  /* And close the session */
  pcap_close(handle);
  return(0);
}
