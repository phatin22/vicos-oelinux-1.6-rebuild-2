package main

import (
	"fmt"
	"image/color"
	"io"
	"math"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/os-vector/vector-gobot/pkg/vscreen"
)

var spinner []string = []string{`-`, `\`, `|`, `/`}
var statusChan chan string
var currentPercentageChan chan string
var totalPercentageChan chan string
var totalRangeStart int
var totalRangeEnd int
var stopChan chan bool
var stoppedChan chan bool
var v2 bool

// percentage, is-bot-2.0
// [============] 20% = 1.0
// [=========] 20% = 2.0
func makePercentageString(percentage int) string {
	var barsMax int
	if v2 {
		barsMax = 11
	} else {
		barsMax = 14
	}
	var percentageBar string = "["
	barsCount := int(math.Round(float64(percentage) / float64(100) * float64(barsMax)))
	emptyCount := barsMax - barsCount
	for i := 1; i <= barsCount; i++ {
		if barsCount == i {
			percentageBar += "M"
		} else {
			percentageBar += "#"
		}
	}
	for range emptyCount {
		percentageBar += "="
	}
	percentageBar += "] " + strconv.Itoa(percentage) + "%"
	return percentageBar
}

func updateStatus(status string) {
	select {
	case statusChan <- status:
	default:
	}
}

func updateCurrentPercentage(percentage int) {
	percentageString := makePercentageString(percentage)
	select {
	case currentPercentageChan <- percentageString:
	default:
	}
}

func updateTotalPercentage(percentage int) {
	if totalRangeEnd == 0 {
		return
	}
	totalRange := totalRangeEnd - totalRangeStart
	totalPercentage := int(math.Round(float64(percentage)/float64(100)*float64(totalRange))) + totalRangeStart
	percentageString := makePercentageString(totalPercentage)
	select {
	case totalPercentageChan <- percentageString:
	default:
	}
}

func updateTotalPercentageRange(start, end int) {
	totalRangeStart = start
	totalRangeEnd = end
}

func displayRenderer() {
	var status string
	var totalPercentage string
	var currentPercentage string
	var stop bool
	var currentSpinny int
	go func() {
		// cursed
		for status = range statusChan {
		}
	}()
	go func() {
		for totalPercentage = range totalPercentageChan {
		}
	}()
	go func() {
		for currentPercentage = range currentPercentageChan {
		}
	}()
	go func() {
		for stop = range stopChan {
		}
	}()
	for {
		newCurrentPercentage := strings.Replace(currentPercentage, "M", spinner[currentSpinny], -1)
		newTotalPercentage := strings.Replace(totalPercentage, "M", spinner[currentSpinny], -1)
		if currentSpinny == len(spinner)-1 {
			currentSpinny = 0
		} else {
			currentSpinny++
		}
		if stop {
			vscreen.SetScreen(vscreen.CreateTextImage("Rebooting..."))
			select {
			case stoppedChan <- true:
			default:
			}
			break
		}
		var lines []vscreen.Line
		lines = append(lines, vscreen.Line{
			Text:  status,
			Color: color.RGBA{R: 0, G: 255, B: 0, A: 255},
		})
		lines = append(lines, vscreen.Line{
			Text:  newCurrentPercentage,
			Color: color.RGBA{R: 255, G: 255, B: 255, A: 255},
		})
		lines = append(lines, vscreen.Line{
			Text:  "",
			Color: color.RGBA{R: 255, G: 255, B: 255, A: 255},
		})
		lines = append(lines, vscreen.Line{
			Text:  "Total progress:",
			Color: color.RGBA{R: 255, G: 255, B: 255, A: 255},
		})
		lines = append(lines, vscreen.Line{
			Text:  newTotalPercentage,
			Color: color.RGBA{R: 255, G: 255, B: 255, A: 255},
		})
		vscreen.SetScreen(vscreen.CreateTextImageFromLines(lines))
		time.Sleep(time.Millisecond * 200)
	}
}

func sizeOfGzipContents(zippy string) int {
	zipOut, err := exec.Command("/usr/bin/pigz", "-l", zippy).Output()
	if err != nil {
		fmt.Println("sizeOfGzipContents err:", err)
		return 0
	}
	zipOutToParse := string(zipOut)
	lines := strings.Split(zipOutToParse, "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[1] != "original" {
			size, err := strconv.ParseInt(fields[1], 10, 64)
			if err != nil {
				fmt.Println("int conv error in sizeOfGzipContents: ", err)
				return 0
			}
			fmt.Println(int(size))
			return int(size)
		}
	}
	fmt.Println("hmm error: ", zipOutToParse)
	return 0

}

func dump(status, zip, dest string, percentageRangeStart, percentageRangeEnd int) {
	updateStatus(status)
	updateTotalPercentageRange(percentageRangeStart, percentageRangeEnd)
	var outputted int
	gzipSize := sizeOfGzipContents(zip)
	ifDD := exec.Command("/usr/bin/pigz", "-dc", zip)
	ofDD := exec.Command("/usr/bin/dd", "of="+dest)
	rc, err := ifDD.StdoutPipe()
	if err != nil {
		fmt.Println("dd pipe error", err)
		return
	}
	wr, err := ofDD.StdinPipe()

	done := make(chan struct{})

	go func() {
		defer close(done)
		bufSize := 1000000
		buf := make([]byte, bufSize)
		for {
			n, err := rc.Read(buf)
			if n > 0 {
				outputted += n
				percent := int(math.Round(float64(outputted) / float64(gzipSize) * 100))
				updateCurrentPercentage(percent)
				updateTotalPercentage(percent)
				_, werr := wr.Write(buf[:n])
				if werr != nil {
					fmt.Println("BUFFER WRITE ERROR:", werr)
					return
				}
			}
			if err != nil {
				if err != io.EOF {
					fmt.Println("READ ERROR:", err)
				}
				return
			}
		}
	}()

	if err := ifDD.Start(); err != nil {
		fmt.Println("ifDD start failed:", err)
		return
	}
	if err := ofDD.Start(); err != nil {
		fmt.Println("ofDD start failed:", err)
		return
	}

	<-done

	ifDD.Wait()
	wr.Close()
	ofDD.Wait()
}

func main() {
	statusChan = make(chan string)
	currentPercentageChan = make(chan string)
	totalPercentageChan = make(chan string)
	stopChan = make(chan bool)
	vscreen.InitLCD()
	vscreen.BlackOut()
	v2, _ = vscreen.IsMidas()
	go displayRenderer()
	time.Sleep(time.Millisecond * 50)
	updateStatus("Starting...")
	updateCurrentPercentage(0)
	updateTotalPercentageRange(0, 100)
	updateTotalPercentage(0)

	dump("Writing Recovery", "/data/recovery.img.gz", "/dev/block/bootdevice/by-name/recoveryfs", 0, 8)
	dump("Writing RecoveryFS", "/data/recoveryfs.img.gz", "/dev/block/bootdevice/by-name/recoveryfs", 9, 100)
	
	go func() {
		for range stoppedChan {
			// reboot here
			os.Exit(0)
		}
	}()
	select {
	case stopChan <- true:
	default:
	}
}
